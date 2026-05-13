data "aws_vpc" "default" {
  default = true
}

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_route_table" "main" {
  vpc_id = aws_vpc.default.id
  filter {
    name   = "association.main"
    values = ["true"]
  }
}