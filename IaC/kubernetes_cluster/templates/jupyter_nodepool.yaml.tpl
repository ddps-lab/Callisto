apiVersion: karpenter.sh/v1
kind: NodePool
metadata:
  name: jupyter-nodepool
spec:
  disruption:
    consolidateAfter: 1m0s
    consolidationPolicy: WhenEmpty
  template:
    metadata: {}
    spec:
      nodeClassRef:
        name: jupyter-nodeclass
        group: karpenter.k8s.aws
        kind: EC2NodeClass
      requirements:
      - key: kubernetes.io/os
        operator: In
        values: ["linux"]
      - key: kubernetes.io/arch
        operator: In
        values: ["amd64"]
      - key: karpenter.sh/capacity-type
        operator: In
        values: ["spot"]
  limits:
    cpu: 1000
    memory: 1000Gi
---
apiVersion: karpenter.k8s.aws/v1
kind: EC2NodeClass
metadata:
  name: jupyter-nodeclass
spec:
  amiSelectorTerms:
    - alias: bottlerocket@v1.20.4
  role: "${node_role_name}"
  subnetSelectorTerms:
    - tags:
        karpenter.sh/discovery: "${eks_cluster_name}"
  securityGroupSelectorTerms:
    - tags:
        karpenter.sh/discovery: "${eks_cluster_name}"
  blockDeviceMappings:
    - deviceName: /dev/xvda
      ebs:
        volumeSize: 30Gi
        volumeType: gp3
        iops: 3000
        deleteOnTermination: true
        throughput: 300