package main

import (
  "context"
  _ "embed"
  "github.com/open-policy-agent/opa/rego"
  "github.com/rs/zerolog/log"
  v1 "k8s.io/api/admission/v1"
  meta "k8s.io/apimachinery/pkg/apis/meta/v1"
  "net/http"

  "github.com/gin-contrib/logger"
  "github.com/gin-gonic/gin"
  //"encoding/json"
)

//go:embed admissions.rego
var regoFile string

func main() {
  r := gin.Default()
  r.Use(logger.SetLogger())
  gin.SetMode(gin.DebugMode)

  r.POST("/validate", func(c *gin.Context) {
    review := NewAdmissionsReview(c)
    review.Response.Allowed = OpaQuery("data.kubernetes.admission.admit", review).(bool)
    violations := OpaQuery("data.kubernetes.admission.violations", review).([]interface{})
    review.Response.Warnings = violationsToString(violations)

    c.JSON(http.StatusOK, &review.Response)
  })
  r.RunTLS(":8080", "/etc/ssl/certs/cert.pem", "/etc/ssl/certs/key.pem")
  //r.RunTLS(":8080", "certs/cert.pem", "certs/key.pem")
}

//NewAdmissionsReview uses the gin context to unmarshal the context into a k8 Admissions review and provider sensible defaults
func NewAdmissionsReview(c *gin.Context) v1.AdmissionReview {
  review := v1.AdmissionReview{
    TypeMeta: meta.TypeMeta{},
    Request:  &v1.AdmissionRequest{},
    Response: &v1.AdmissionResponse{},
  }
  if err := c.BindJSON(&review); err != nil {
    log.Err(err).Msg("there was an error binding JSON to the admissions review object")
  }
  review.Response.UID = review.Request.UID
  review.TypeMeta.Kind = "AdmissionReview"
  review.TypeMeta.APIVersion = "admission.k8s.io/v1"
  return review
}

//OpaQuery takes in a query string and an admissions review to evaluate against the query then returns results
func OpaQuery(query string, r v1.AdmissionReview) interface{} {
  ctx := context.TODO()
  admit, err := rego.New(
    rego.Module("admissions.rego", regoFile),
    rego.Query(query),
  ).PrepareForEval(ctx)

  if err != nil {
    log.Err(err).Msg("there was an error with the rego query")
  }
  rs, err := admit.Eval(ctx, rego.EvalInput(r))
  if err != nil {
    log.Err(err).Msg("there was an error with the rego eval")
  }

  return rs[0].Expressions[0].Value
}

func violationsToString(vi []interface{}) []string {
  violations := []string{}
  for i := 0; i < len(vi); i++ {
    if violation, ok := vi[i].(string); ok {
      violations = append(violations, violation)
    }
  }
  return violations
}
