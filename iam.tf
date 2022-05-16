################################################################################
# create_eks_role_policy
################################################################################

resource "aws_iam_role" "eks" {
  name = "cloud5-eks-cluster-iam-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "cloud5-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks.name
}

# Optionally, enable Security Groups for Pods
# Reference: https://docs.aws.amazon.com/eks/latest/userguide/security-groups-for-pods.html
resource "aws_iam_role_policy_attachment" "cloud5-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks.name
}


################################################################################
# IAM Role for EKS Addon "vpc-cni" with AWS managed policy
################################################################################

data "tls_certificate" "eks" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

data "aws_iam_policy_document" "eks_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-node"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "cni" {
  assume_role_policy = data.aws_iam_policy_document.eks_assume_role_policy.json
  name               = "cloud5-eks-vpc-cni-role"
}

resource "aws_iam_role_policy_attachment" "eks" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.cni.name
}

################################################################################
# IAM Role for node_groups
################################################################################

resource "aws_iam_role" "node" {
  name = "cloud5-eks-node-group-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node-AmazonSSMManagedInstanceCore" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node-CloudWatchAgentServerPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.node.name
}

################################################################################
# IAM Role for Bastion host
################################################################################

resource "aws_iam_instance_profile" "bastion_profile" {
  name = "cloud5-bastion-host-profile"
  role = aws_iam_role.bastion.name
}

resource "aws_iam_role" "bastion" {
  name = "cloud5-bastion-host-iam-role"

  assume_role_policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
POLICY
}

################################################################################
# IAM Role for Ingress controller
################################################################################

data "aws_iam_policy_document" "ingress_controller_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_policy" "ingress_controller_policy" {
  name        = "cloud5-ingress-controller-policy"
  description = "My custom ingress controller policy"

  policy = file("${path.module}/policy/ingress_iam_policy.json")
}

resource "aws_iam_role" "ingress_controller" {
  assume_role_policy = data.aws_iam_policy_document.ingress_controller_assume_role_policy.json
  name               = "cloud5-eks-ingress-controller-role"
}

resource "aws_iam_role_policy_attachment" "ingress_controller" {
  policy_arn = aws_iam_policy.ingress_controller_policy.arn
  role       = aws_iam_role.ingress_controller.name
}

################################################################################
# IAM Role for Autuscaling
################################################################################

data "aws_iam_policy_document" "autoscaling_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:cluster-autoscaler"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_policy" "cluster_autoscaler_policy" {
  name        = "cloud5-cluster-autoscaler-policy"
  description = "My custom cluster autoscaler policy"

  policy = file("${path.module}/policy/cluster-autoscaler-policy.json")
}

resource "aws_iam_role" "cluster_autoscaler" {
  assume_role_policy = data.aws_iam_policy_document.autoscaling_assume_role_policy.json
  name               = "cloud5-eks-cluster-autoscaler-role"
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler" {
  policy_arn = aws_iam_policy.cluster_autoscaler_policy.arn
  role       = aws_iam_role.cluster_autoscaler.name
}

################################################################################
# IAM Role for EBS CSI Driver
################################################################################

data "aws_iam_policy_document" "ebs_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_policy" "ebs_csi_policy" {
  name        = "cloud5-ebs-csi-policy"
  description = "My custom ebs csi policy"

  policy = file("${path.module}/policy/ebs-csi-iam-policy.json")
}

resource "aws_iam_role" "ebs_csi" {
  assume_role_policy = data.aws_iam_policy_document.ebs_assume_role_policy.json
  name               = "cloud5-eks-ebs-csi-role"
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  policy_arn = aws_iam_policy.ebs_csi_policy.arn
  role       = aws_iam_role.ebs_csi.name
}


################################################################################
# IAM Role for EFS CSI Driver
################################################################################

data "aws_iam_policy_document" "efs_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:efs-csi-controller-sa"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_policy" "efs_csi_policy" {
  name        = "cloud5-efs-csi-policy"
  description = "My custom efs csi policy"

  policy = file("${path.module}/policy/ebs-csi-iam-policy.json")
}

resource "aws_iam_role" "efs_csi" {
  assume_role_policy = data.aws_iam_policy_document.efs_assume_role_policy.json
  name               = "cloud5-eks-efs-csi-role"
}

resource "aws_iam_role_policy_attachment" "efs_csi" {
  policy_arn = aws_iam_policy.efs_csi_policy.arn
  role       = aws_iam_role.efs_csi.name
}