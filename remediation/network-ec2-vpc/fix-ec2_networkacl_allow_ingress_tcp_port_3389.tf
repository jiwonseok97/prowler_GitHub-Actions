#
# Restrict RDP access to the network ACL
#
resource "aws_network_acl_rule" "remediation_rdp_ingress_deny" {
  network_acl_id = "acl-0572e1ab82993bb20"
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 3389
  to_port        = 3389
}

#
# Optionally, add a bastion host to allow controlled RDP access
#
# data "aws_subnets" "private" {
#   vpc_id = "vpc-0123456789abcdef"
# }
# 
# resource "aws_instance" "remediation_bastion" {
#   ami           = "ami-0123456789abcdef"
#   instance_type = "t2.micro"
#   subnet_id     = tolist(data.aws_subnets.private.ids)[0]
# 
#   vpc_security_group_ids = [
#     "sg-0123456789abcdef"
#   ]
# 
#   tags = {
#     Name = "remediation-bastion"
#   }
# }
