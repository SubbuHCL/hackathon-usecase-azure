variable "vpc_network_name" {
    type=string
    default = "hcl-hackathon-vpc-network"
}

variable "gke_cluster_name" {
    type=string
    default = "hcl-hackathon-gke-cluster"
}

variable "gke_node_pool_name" {
    type=string
    default = "hcl-hackathon-gke-node-pool"
}