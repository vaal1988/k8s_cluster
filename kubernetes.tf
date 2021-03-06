locals {
  libvirt_vms = {
    "master-node"  = { vcpu = "2", memory = "2048", username = "centos", password = "password", grow_disk= "+12G", groups = ["kubernetes_master"] },
    "node-1"       = { vcpu = "2", memory = "2048", username = "centos", password = "password", grow_disk= "+17G", groups = ["kubernetes_node"] },
    # "node-2"       = { vcpu = "2", memory = "2048", username = "centos", password = "password", grow_disk= "+17G", groups = ["kubernetes_node"] },
  }
}


data "template_file" "user_data" {
  for_each = local.libvirt_vms
  template = templatefile("templates/user_data.tpl", {
  username = each.value.username,
  password = each.value.password
  })
}

data "template_file" "meta_data" {
  for_each = local.libvirt_vms
  template = templatefile("templates/meta_data.tpl", {
  hostname = each.key
  })
}

resource "libvirt_cloudinit_disk" "list" {
  for_each       = local.libvirt_vms
  name           = "cloudinit_${each.key}.iso"
  user_data      = data.template_file.user_data[each.key].rendered
  meta_data      = data.template_file.meta_data[each.key].rendered
}

resource "libvirt_volume" "list" {
  for_each       = local.libvirt_vms
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
  for_each       = local.libvirt_vms
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
      "sudo yum install -y epel-release",
      "sudo yum install -y python2 python2-pip",
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
    %{ for key in each.value.groups ~}
    ansible localhost -m ini_file --args='path=ansible/hosts.ini section=${key} option="${self.name} ansible_host" value="${self.network_interface[0].addresses[0]} ansible_user=${each.value.username} ansible_password=${each.value.password}" no_extra_spaces=yes'
    %{ endfor ~}
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = "ansible localhost -m lineinfile --args='path=ansible/hosts.ini regexp=\"^${self.name} ansible_host\" state=absent'"
  }

}

resource "null_resource" "ansible_run" {
  depends_on = [libvirt_domain.list]

  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    working_dir = "./ansible"
    command     = "ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i hosts.ini main.yml --become"
  }
}