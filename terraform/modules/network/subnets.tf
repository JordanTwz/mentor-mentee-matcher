resource "aws_subnet" "public" {
    vpc_id = aws_vpc.main.id
    for_each = var.public_subnets
    cidr_block = each.value
    tags = merge(
        var.tags,
        {
            Name = "${var.env}-${var.aws_region}-${var.app_name}-public-${each.key}"
            Tier = "public"
        }
    )
}
