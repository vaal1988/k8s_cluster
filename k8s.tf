locals {
  k8s = {
    "master-node"  = { vcpu = "2", memory = "2048", username = "centos", password = "password", grow_disk= "+12G", roles = ["k8s_master"] },
    "node-1"       = { vcpu = "1", memory = "1024", username = "centos", password = "password", grow_disk= "+12G", roles = ["k8s_node"] },
    # "node-2"       = { vcpu = "1", memory = "1024", username = "centos", password = "password", roles = ["k8s_node"] },
  }
}

data "template_file" "user_data" {
  for_each = local.k8s
  template = templatefile("templates/user_data.tpl", {
  username = each.value.username,
  password = each.value.password
  })
}

data "template_file" "meta_data" {
  for_each = local.k8s
  template = templatefile("templates/meta_data.tpl", {
  hostname = each.key
  })
}

resource "libvirt_cloudinit_disk" "list" {
  for_each       = local.k8s
  name           = "cloudinit_${each.key}.iso"
  user_data      = data.template_file.user_data[each.key].rendered
  meta_data      = data.template_file.meta_data[each.key].rendered
}

resource "libvirt_volume" "list" {
  for_each       = local.k8s
  name           = "${each.key}.qcow2"
  pool           = "default"
  source         = "/var/lib/libvirt/images/CentOS-7-x86_64-GenericCloud-2009.qcow2"
  format         = "qcow2"
  depends_on = [
    null_resource.centos7_image,
  ]
  
  provisioner "local-exec" {
    command = "sudo qemu-img resize ${self.id} ${each.value.grow_disk}"
  }

}

resource "libvirt_domain" "list" {
  for_each       = local.k8s
  name           = each.key
  memory         = each.value.memory
  vcpu           = each.value.vcpu

  network_interface {
    network_name   = "default"
    wait_for_lease = true
  }

  disk {
    volume_id    = libvirt_volume.list[each.key].id
  }

  cloudinit      = libvirt_cloudinit_disk.list[each.key].id

  console {
    type         = "pty"
    target_type  = "serial"
    target_port  = "0"
  }

  graphics {
    type        = "vnc"
    listen_type = "address"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install -y python3",
    ]
    connection {
      type                = "ssh"
      user                = each.value.username
      host                = self.network_interface[0].addresses[0]
      password            = each.value.password
      timeout             = "2m"
    }
  }

  provisioner "local-exec" {
  command = <<-EOT
  %{ for key in each.value.roles ~}
  ANSIBLE_HOST_KEY_CHECKING=False ansible all -i '${self.network_interface[0].addresses[0]},' -m include_role -a name=${key} --become --extra-vars 'ansible_user=${each.value.username} ansible_password=${each.value.password}'
  %{ endfor ~}
  EOT
  }

}

output "ipaddresses" {
  value = {
    for ip, vm in libvirt_domain.list : ip => vm.network_interface[0].addresses[0]
  }
}