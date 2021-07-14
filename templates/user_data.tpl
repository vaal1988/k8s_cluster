#cloud-config
# ---> https://cloudinit.readthedocs.io/en/latest/topics/examples.html

users:
  - name: centos
    ssh_authorized_keys:
      - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC+1iYn3TMtszHqJOfCZcGU7Oq53NUUiZ+v8HnzxWdVvV7JYxGWWElIUa2QjxTaaq8ePYi9gyBXoA8A0MkxBGd34Hwm/Vw38ugnhfZNYEbfyJ1pIWjpHxUgN83B4EZCUjjGUBVGsofjrEFIaJZOrJ/egLcTkXA4s3mjFAz2or94yzjqPPsSToVVI9NYGvfLPgN5hI7UCytKQcpxvO233bGJImBXfino7/x3P6bXKUgFDc0OiqpBBUaqP1R8sxIqUI8kuAlYmyYCpLuHlwoWXg9MW86SZFiHYKVfWvY/VEhiMnJzAG/Pv+2QakccXkMuQzmtG9xUCdDj4Ky0RUlCMhih/2ZypmEe2wNkwvA9TDWRqi/ucOz4v8fi4FmMkb9E/XAJwi2tkJM9fVJPFphZ1yGrep/xEbL6EMICBrppnI9kRcncUizGk6vP/8chVb4tA1d82oHrG3E3RD6iQ7CXZ/P3ShnlR4DE/19Ip9qt2o9ogvXW8ET4/bKOB3FdrC7g8B8=
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    shell: /bin/bash
    groups: wheel

chpasswd:
  list: |
    ${username}:${password}
  expire: False

# install packages
# packages:
#   - openssh-server
#   - epel-release
#   - nano

