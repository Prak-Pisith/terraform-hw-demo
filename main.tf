# Create VPC
resource "huaweicloud_vpc" "my_vpc" {
  name       = "terraform_vpc"
  cidr       = "10.0.0.0/16"
}

# Create public subnet
resource "huaweicloud_vpc_subnet" "public_subnet" {
  name       = "terraform_public_subnet"
  cidr       = "10.0.1.0/24"
  vpc_id     = huaweicloud_vpc.my_vpc.id
  gateway_ip = "10.0.1.1"
}

# Create private subnet
resource "huaweicloud_vpc_subnet" "private_subnet" {
  name       = "terraform_private_subnet"
  cidr       = "10.0.2.0/24"
  vpc_id     = huaweicloud_vpc.my_vpc.id
  gateway_ip = "10.0.2.1"
}

# Create security group
resource "huaweicloud_networking_secgroup" "my_sec_group" {
  name = "terraform_secgroup"
  description = "sample sec-group created by terraform"
  delete_default_rules = true
}
resource "huaweicloud_networking_secgroup_rule" "my_sec_group_rules" {
  direction = "ingress"
  ethertype = "IPv4"
  protocol = "tcp"
  port_range_min = 22
  port_range_max = 22
  remote_ip_prefix = "0.0.0.0/0"
  security_group_id = huaweicloud_networking_secgroup.my_sec_group.id
}

# Keypair
# resource "huaweicloud_compute_keypair" "demo-server-key" {
#   name     = "demo-server-key"
#   public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCFdmQrEZXEUws7gznDRTpCdb9R1LyUMWtwFAKK3Bs25VAoGWXH62QqS/FMLvvmL6JYl/JnEhhGnb+TVMuFnIi1Xwi8tsWuDnu1M5izPn47S1BDoJabWJAtlAzOKfq9dSfuv2CrRf4QaWqXFIRs/DiXY7AuXHURrpUcpltvE12onWyijCYBJwoIsMpiyhYPeQ6xEsfLZogPHMZZXfKmarM1TzD6nQb6ldLbH15FIVbC1ApoxfcUZH9llc19stAeg6TdPQYkxNT36UmikluI46AwG9aNBmP9BW9CuGTEHYmB73d7iVz+euYbePmcFhDXXGecW4QKbX8rwqnFjdmpN2kF Generated-by-Nova\n"
# }

# Create ECS

## Create AZ
data "huaweicloud_availability_zones" "my_az" {
  
}

data "huaweicloud_compute_flavors" "my_flavors" {
  availability_zone = data.huaweicloud_availability_zones.my_az.names[0]
  performance_type = "normal"
  cpu_core_count = 2
  memory_size = 4
}

data "huaweicloud_images_image" "my_image" {
  name = "Ubuntu 22.04 server 64bit"
  most_recent = true
}

resource "huaweicloud_compute_instance" "my_instance" {
  name = "my_terraform_instance"
  image_id = data.huaweicloud_images_image.my_image.id
  flavor_id = data.huaweicloud_compute_flavors.my_flavors.ids[0]
  availability_zone = data.huaweicloud_availability_zones.my_az.names[0]
  security_group_ids = [huaweicloud_networking_secgroup.my_sec_group.id]
  # key_pair = huaweicloud_compute_keypair.demo-server-key.name
  network {
    uuid = huaweicloud_vpc_subnet.public_subnet.id
  }
}

# Associate EIP

resource "huaweicloud_vpc_eip" "my_eip" {
  publicip {
    type = "5_bgp"
  }
  bandwidth {
    name = "my_eip_bandwidth"
    size = 8
    share_type = "PER"
    charge_mode = "traffic"
  }
}

resource "huaweicloud_compute_eip_associate" "associated" {
  public_ip = huaweicloud_vpc_eip.my_eip.address
  instance_id = huaweicloud_compute_instance.my_instance.id
}