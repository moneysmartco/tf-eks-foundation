#------------------------------------------
# Control Plane Security Group
#------------------------------------------
resource "aws_security_group" "control_plane_sg" {
  name        = "tf-${var.project_name}-${var.env}-eks-control-plane-sg"
  description = "${var.project_name} ${var.env} EKS control plane secgroup"
  vpc_id      = var.vpc_id

  tags = local.control_plane_security_group_tags
}

#------------------------------------------
# Worker Nodes Security Group
#------------------------------------------
resource "aws_security_group" "worker_sg" {
  name        = "tf-${var.project_name}-${var.env}-eks-worker-sg"
  description = "${var.project_name} ${var.env} EKS worker node secgroup"
  vpc_id      = var.vpc_id

  tags = local.worker_node_security_group_tags

  lifecycle {
    ignore_changes = [ingress]
  }
}

#------------------------------------------
# Rules on worker
#------------------------------------------
resource "aws_security_group_rule" "allow_worker_node_intra_connection" {
  security_group_id = aws_security_group.worker_sg.id
  description       = "Allow node to communicate with each other"

  type      = "ingress"
  self      = true
  protocol  = "-1"
  from_port = 0
  to_port   = 0
}

resource "aws_security_group_rule" "allow_master_to_worker_kubelets_and_pods" {
  security_group_id = aws_security_group.worker_sg.id
  description       = "Allow worker Kubelets and pods to receive communication from the cluster control plane"

  type                     = "ingress"
  source_security_group_id = aws_security_group.control_plane_sg.id
  protocol                 = "tcp"
  from_port                = 1025
  to_port                  = 65535
}

resource "aws_security_group_rule" "allow_master_to_worker_extension_api_server" {
  security_group_id = aws_security_group.worker_sg.id
  description       = "Allow pods running extension API servers on port 443 to receive communication from cluster control plane"

  type                     = "ingress"
  source_security_group_id = aws_security_group.control_plane_sg.id
  protocol                 = "tcp"
  from_port                = 443
  to_port                  = 443
}

resource "aws_security_group_rule" "allow_bastion_to_worker_ssh" {
  security_group_id = aws_security_group.worker_sg.id
  description       = "Allow bastion host to access"

  type                     = "ingress"
  source_security_group_id = var.bastion_security_gp
  protocol                 = "tcp"
  from_port                = 22
  to_port                  = 22
}

resource "aws_security_group_rule" "allow_worker_egress_worldwide" {
  security_group_id = aws_security_group.worker_sg.id
  description       = "Allow worker egress worldwide"

  type        = "egress"
  cidr_blocks = ["0.0.0.0/0"]
  protocol    = "-1"
  from_port   = 0
  to_port     = 0
}

#------------------------------------------
# Rules on master
#------------------------------------------
resource "aws_security_group_rule" "allow_master_to_worker_pods" {
  security_group_id = aws_security_group.control_plane_sg.id
  description       = "Allow the cluster control plane to communicate with worker Kubelet and pods"

  type                     = "egress"
  source_security_group_id = aws_security_group.worker_sg.id
  protocol                 = "tcp"
  from_port                = 1025
  to_port                  = 65535
}

resource "aws_security_group_rule" "allow_master_to_worker_api" {
  security_group_id = aws_security_group.control_plane_sg.id
  description       = "Allow the cluster control plane to communicate with pods running extension API servers on port 443"

  type                     = "egress"
  source_security_group_id = aws_security_group.worker_sg.id
  protocol                 = "tcp"
  from_port                = 443
  to_port                  = 443
}

resource "aws_security_group_rule" "allow_worker_to_master_api" {
  security_group_id = aws_security_group.control_plane_sg.id
  description       = "Allow pods to communicate with the cluster API Server"

  type                     = "ingress"
  source_security_group_id = aws_security_group.worker_sg.id
  protocol                 = "tcp"
  from_port                = 443
  to_port                  = 443
}

