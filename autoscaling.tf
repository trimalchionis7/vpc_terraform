# Adding autoscaling to EC2 instances in private subnet

# Create launch template
resource "aws_launch_template" "public_launch_template" {
  name                   = "public_launch_template"
  image_id               = data.aws_ami.latest_linux_ami.id
  instance_type          = "t2.micro"
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.asg_security_group.id]
  user_data              = base64encode(data.template_file.user-data.rendered)
}

# Create autoscaling group
resource "aws_autoscaling_group" "private_asg" {
  name                      = "private_asg"
  min_size                  = 1
  max_size                  = 4
  desired_capacity          = 2
  vpc_zone_identifier       = [aws_subnet.private-1.id, aws_subnet.private-2.id]
  target_group_arns         = [aws_lb_target_group.target-group.arn]
  health_check_type         = "ELB"
  health_check_grace_period = 300

  tag {
    key                 = "DevASGInstance"
    value               = "Dev"
    propagate_at_launch = true
  }

  launch_template {
    id      = aws_launch_template.public_launch_template.id
    version = "$Latest"
  }
}

# Create autoscaling policy
resource "aws_autoscaling_policy" "private_asg_policy" {
  name                   = "private_asg_policy"
  autoscaling_group_name = aws_autoscaling_group.private_asg.name
  policy_type            = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 60.0
  }
}