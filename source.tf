# resource "null_resource" "centos8_image" {
#   provisioner "local-exec" {
#     command = "ansible localhost --become -m get_url -a 'url=https://cloud.centos.org/centos/8/x86_64/images/CentOS-8-GenericCloud-8.4.2105-20210603.0.x86_64.qcow2 dest=/var/lib/libvirt/images/CentOS-8-GenericCloud-8.4.2105-20210603.0.x86_64.qcow2'"
#   }
# }

resource "null_resource" "centos7_image" {
  provisioner "local-exec" {
    command = "ansible localhost --become -m get_url -a 'url=https://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud-2009.qcow2 dest=/var/lib/libvirt/images/CentOS-7-x86_64-GenericCloud-2009.qcow2'"
  }
}

# resource "time_sleep" "wait_30_seconds" {
#   create_duration = "30s"
# }