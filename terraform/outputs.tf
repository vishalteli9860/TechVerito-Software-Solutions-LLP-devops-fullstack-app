output "jenkins_public_ip" {
  value = aws_instance.jenkins.public_ip
}

output "jenkins_url" {
  value = "http://${aws_instance.jenkins.public_ip}:8081"
}

output "application_url" {
  value = "http://${aws_instance.k3s.public_ip}:30080"
}

output "k3s_public_ip" {
  value = aws_instance.k3s.public_ip
}

output "k3s_ssh_command" {
  value = "ssh -i <your-private-key.pem> ubuntu@${aws_instance.k3s.public_ip}"
}

output "jenkins_ssh_command" {
  value = "ssh -i <your-private-key.pem> ubuntu@${aws_instance.jenkins.public_ip}"
}
