#------------------------------------------
# Control Plane Security Group
#------------------------------------------
resource "aws_security_group" "control_plane_sg" {
  name        = "tf-${var.project_name}-${var.env}-eks-control-plane-sg"
  description = "${var.project_name} ${var.env} EKS control plane secgroup"
  vpc_id      = "${var.vpc_id}"

  tags = "${local.control_plane_security_group_tags}"
}

#------------------------------------------
# Worker Nodes Security Group
#------------------------------------------
resource "aws_security_group" "worker_sg" {
  name        = "tf-${var.project_name}-${var.env}-eks-worker-sg"
  description = "${var.project_name} ${var.env} EKS worker node secgroup"
  vpc_id      = "${var.vpc_id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
    description = "Allow node to communicate with each other"
  }

  ingress {
    from_port       = 1025
    to_port         = 65535
    protocol        = "tcp"
    security_groups = ["${aws_security_group.control_plane_sg.id}"]
    description     = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = ["${aws_security_group.control_plane_sg.id}"]
    description     = "Allow pods running extension API servers on port 443 to receive communication from cluster control plane"
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = ["${var.bastion_security_gp}"]
    description     = "Allow bastion host to access"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${local.worker_node_security_group_tags}"
}

resource "aws_security_group_rule" "allow_master_to_worker_pods" {
  security_group_id        = "${aws_security_group.control_plane_sg.id}"
  source_security_group_id = "${aws_security_group.worker_sg.id}"
  description              = "Allow the cluster control plane to communicate with worker Kubelet and pods"

  type      = "egress"
  protocol  = "tcp"
  from_port = 1025
  to_port   = 65535
}

resource "aws_security_group_rule" "allow_master_to_worker_api" {
  security_group_id        = "${aws_security_group.control_plane_sg.id}"
  source_security_group_id = "${aws_security_group.worker_sg.id}"
  description              = "Allow the cluster control plane to communicate with pods running extension API servers on port 443"

  type      = "egress"
  protocol  = "tcp"
  from_port = 443
  to_port   = 443
}

resource "aws_security_group_rule" "allow_worker_to_master_api" {
  security_group_id        = "${aws_security_group.control_plane_sg.id}"
  source_security_group_id = "${aws_security_group.worker_sg.id}"
  description              = "Allow pods to communicate with the cluster API Server"

  type      = "ingress"
  protocol  = "tcp"
  from_port = 443
  to_port   = 443
}
