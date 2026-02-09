#
# Create an interface VPC endpoint for the EC2 service in the existing VPC
#
resource "aws_vpc_endpoint" "remediation_ec2_endpoint" {
  vpc_id            = "vpc-0565167ce4f7cc871"
  service_name      = "com.amazonaws.ap-northeast-2.ec2"
  vpc_endpoint_type = "Interface"
  private_dns_enabled = true

  security_group_ids = [
    aws_security_group.remediation_ec2_endpoint_sg.id
  ]

  subnet_ids = [
    data.aws_subnet.private_subnets[0].id,
    data.aws_subnet.private_subnets[1].id,
    data.aws_subnet.private_subnets[2].id
  ]
}

#
# Create a security group for the EC2 VPC endpoint
#
resource "aws_security_group" "remediation_ec2_endpoint_sg" {
  name        = "remediation_ec2_endpoint_sg"
  description = "Security group for EC2 VPC endpoint"
  vpc_id      = "vpc-0565167ce4f7cc871"
}

#
# Restrict the EC2 VPC endpoint policy to the minimum required permissions
#
resource "aws_vpc_endpoint_policy" "remediation_ec2_endpoint_policy" {
  vpc_endpoint_id = aws_vpc_endpoint.remediation_ec2_endpoint.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow",
        Principal = "*",
        Action = [
          "ec2:DescribeAccountAttributes",
          "ec2:DescribeAddresses",
          "ec2:DescribeAvailabilityZones",
          "ec2:DescribeClientVpnAuthorizationRules",
          "ec2:DescribeClientVpnConnections",
          "ec2:DescribeClientVpnEndpoints",
          "ec2:DescribeCustomerGateways",
          "ec2:DescribeDhcpOptions",
          "ec2:DescribeEgressOnlyInternetGateways",
          "ec2:DescribeFlowLogs",
          "ec2:DescribeHostReservationOfferings",
          "ec2:DescribeHostReservations",
          "ec2:DescribeHosts",
          "ec2:DescribeIamInstanceProfileAssociations",
          "ec2:DescribeIdentityIdFormat",
          "ec2:DescribeImageAttribute",
          "ec2:DescribeImages",
          "ec2:DescribeImportImageTasks",
          "ec2:DescribeImportSnapshotTasks",
          "ec2:DescribeInstanceAttribute",
          "ec2:DescribeInstanceCreditSpecifications",
          "ec2:DescribeInstanceEventNotificationAttributes",
          "ec2:DescribeInstanceStatus",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeInstances",
          "ec2:DescribeInternetGateways",
          "ec2:DescribeKeyPairs",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeMovingAddresses",
          "ec2:DescribeNatGateways",
          "ec2:DescribeNetworkAcls",
          "ec2:DescribeNetworkInterfaceAttribute",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DescribePlacementGroups",
          "ec2:DescribePrefixLists",
          "ec2:DescribeRegions",
          "ec2:DescribeReservedInstances",
          "ec2:DescribeReservedInstancesListings",
          "ec2:DescribeReservedInstancesModifications",
          "ec2:DescribeReservedInstancesOfferings",
          "ec2:DescribeRouteTables",
          "ec2:DescribeScheduledInstanceAvailability",
          "ec2:DescribeScheduledInstances",
          "ec2:DescribeSecurityGroupReferences",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeSnapshotAttribute",
          "ec2:DescribeSnapshots",
          "ec2:DescribeSpotDatafeedSubscription",
          "ec2:DescribeSpotFleetInstances",
          "ec2:DescribeSpotFleetRequestHistory",
          "ec2:DescribeSpotFleetRequests",
          "ec2:DescribeSpotInstanceRequests",
          "ec2:DescribeSpotPriceHistory",
          "ec2:DescribeStaleSecurityGroups",
          "ec2:DescribeSubnets",
          "ec2:DescribeTags",
          "ec2:DescribeTrafficMirrorFilters",
          "ec2:DescribeTrafficMirrorSessions",
          "ec2:DescribeTrafficMirrorTargets",
          "ec2:DescribeTransitGatewayAttachments",
          "ec2:DescribeTransitGatewayMulticastDomains",
          "ec2:DescribeTransitGatewayPeeringAttachments",
          "ec2:DescribeTransitGatewayRouteTables",
          "ec2:DescribeTransitGateways",
          "ec2:DescribeTransitVirtualInterfaces",
          "ec2:DescribeVolumeAttribute",
          "ec2:DescribeVolumeStatus",
          "ec2:DescribeVolumes",
          "ec2:DescribeVolumesModifications",
          "ec2:DescribeVpcAttribute",
          "ec2:DescribeVpcClassicLink",
          "ec2:DescribeVpcClassicLinkDnsSupport",
          "ec2:DescribeVpcEndpointConnectionNotifications",
          "ec2:DescribeVpcEndpointConnections",
          "ec2:DescribeVpcEndpointServiceConfigurations",
          "ec2:DescribeVpcEndpointServicePermissions",
          "ec2:DescribeVpcEndpointServices",
          "ec2:DescribeVpcEndpoints",
          "ec2:DescribeVpcPeeringConnections",
          "ec2:DescribeVpcs",
          "ec2:DescribeVpnConnections",
          "ec2:DescribeVpnGateways"
        ]
      }
    ]
  })
}

#
# Retrieve the private subnets in the existing VPC
#
data "aws_subnet" "private_subnets" {
  vpc_id = "vpc-0565167ce4f7cc871"
  filter {
    name   = "tag:Tier"
    values = ["private"]
  }
  count = 3
}