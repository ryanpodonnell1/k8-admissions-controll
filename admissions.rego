package kubernetes.admission

#By Default Allow Pod to Provision
default admit = true

admit = false {
	count(violations) > 0
}

#Image Registry Check
violations[msg] {
	violation := "image_check"
	input.request.kind.kind == "Pod"
	some i
	image := input.request.object.spec.containers[i].image
	name := input.request.object.spec.containers[i].name
	not startswith(image, "869111227120.dkr.ecr.us-east-1.amazonaws.com/")
	msg := sprintf("[%v] - pod '%v' is using an unauthorized image '%v' ", [violation, name, image])
}

#Ensure Memory Limits are set
violations[msg] {
	violation := "resource_limits"
	input.request.kind.kind == "Pod"
	containers := input.request.object.spec.containers[_]
	pod := containers.name
	not containers.resources.limits.memory
	msg := sprintf("[%v] - pod '%v' is missing required resource limits (memory)", [violation, pod])
}

#Ensure CPU Limits are set
violations[msg] {
	violation := "resource_limits"
	input.request.kind.kind == "Pod"
	containers := input.request.object.spec.containers[_]
	pod := containers.name
	not containers.resources.limits.cpu
	msg := sprintf("[%v] - pod '%v' is missing required resource limits (cpu)", [violation, pod])
}
