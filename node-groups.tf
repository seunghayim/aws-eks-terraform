resource "aws_eks_node_group" "node" {
  cluster_name    = local.name
  node_group_name = "node"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = module.vpc.private_subnets

  disk_size      = "20"
  instance_types = ["t3.medium"]
  capacity_type  = "SPOT"

  scaling_config {
    desired_size = 1
    max_size     = 4
    min_size     = 1
  }

  update_config {
    max_unavailable = 2
  }

  remote_access {
    source_security_group_ids = [aws_security_group.node-groups.id]
    ec2_ssh_key               = "langhae"
  }

  launch_template {
    name    = "eks-node"
    version = "latest_version"
  }
  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.node-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node-AmazonSSMManagedInstanceCore,
    aws_iam_role_policy_attachment.node-AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.node-CloudWatchAgentServerPolicy,
    aws_eks_cluster.this
  ]

  # tags = {
  #   "k8s.io/cluster-autoscaler/${local.name}" = "shared"
  #   k8s.io / cluster-autoscaler / enabled     = "TRUE"
  # }

}

# resource "tls_private_key" "this" {
#   algorithm = "RSA"
# }

# resource "aws_key_pair" "this" {
#   key_name_prefix = local.name
#   public_key      = tls_private_key.this.public_key_openssh
# }
