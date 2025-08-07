locals {
  base_resource_name = trimsuffix("${var.prefix}-${var.service_name}-${var.environment}", "-")

  effective_network_tags = length(var.network_tags) > 0 ? var.network_tags : [local.base_resource_name]


  minimum_vm_sa_roles = toset([

  ])


  container_spec = {
    "spec" : {
      "containers" : [
        {
          name : var.container_name,
          image : var.container_image,
          command : var.container_command,
          args : var.container_args,
          env : concat(
            [
              for key, value in var.container_env : {
              name  = key
              value = value
            }
            ],
            [
              for secret in var.container_secrets : {
              name  = secret.env_var_name
              value = secret.secret_value
            }
            ]
          ),
          volumeMounts : [
            for volume_mount in var.container_volume_mounts : {
              name      = volume_mount.name
              mountPath = volume_mount.mountPath
            }
          ]
        }
      ],
      "volumes" : [
        for volume in var.container_volumes : {
          name     = volume.name
          hostPath = volume.hostPath
        }
      ],
      "restartPolicy" : var.container_restart_policy
    }
  }
}

