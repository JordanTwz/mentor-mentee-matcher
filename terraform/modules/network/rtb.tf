resource "aws_route_table" "rtb_public" {
    vpc_id = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw_main.id
    }

    tags = merge(
        var.tags,
        {
            Name = "${var.env}-${var.aws_region}-${var.app_name}-public-rtb"
            Tier = "public"
        }
    )
}