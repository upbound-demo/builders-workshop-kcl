import models.io.upbound.awsm.s3.v1beta1 as awsms3v1beta1

oxr = option("params").oxr # observed composite resource
params = oxr.spec.parameters

bucketName = "{}-bucket-{}".format(oxr.metadata.name, oxr.metadata.uid[-5:])

_metadata = lambda name: str -> any {
  {
    name = name
    annotations = {
      "krm.kcl.dev/composition-resource-name" = name
    }
  }
}

_items: [any] = [
    # Bucket in the desired region
    awsms3v1beta1.Bucket{
        metadata: _metadata(bucketName)
        spec = {
            forProvider = {
                region = params.region
            }
        }
    },
    awsms3v1beta1.BucketOwnershipControls{
        metadata: _metadata("{}-boc".format(oxr.metadata.name))
        spec = {
            forProvider = {
                bucketRef = {
                    name = bucketName
                }
                region = params.region
                rule = {
                    objectOwnership = "BucketOwnerPreferred"
                }
            }
        }
    },
    awsms3v1beta1.BucketPublicAccessBlock{
        metadata: _metadata("{}-pab".format(oxr.metadata.name))
        spec = {
            forProvider = {
                bucketRef = {
                    name = bucketName
                }
                region = params.region
                blockPublicAcls: False
                ignorePublicAcls: False
                restrictPublicBuckets: False
                blockPublicPolicy: False
            }
        }
    },
    # ACL for the bucket
    awsms3v1beta1.BucketACL{
        metadata: _metadata("{}-acl".format(oxr.metadata.name))
        spec = {
            forProvider = {
                bucketRef = {
                    name = bucketName
                }
                region = params.region
                acl = params.acl
            }
        }
    },
    # Default encryption for the bucket
    awsms3v1beta1.BucketServerSideEncryptionConfiguration{
        metadata: _metadata("{}-encryption".format(oxr.metadata.name))
        spec = {
            forProvider = {
                region = params.region
                bucketRef = {
                    name = bucketName
                }
                rule = [
                    {
                        applyServerSideEncryptionByDefault = {
                            sseAlgorithm = "AES256"
                        }
                        bucketKeyEnabled = True
                    }
                ]
            }
        }
    }
]

# Set up versioning for the bucket if desired
if params.versioning:
    _items += [
        awsms3v1beta1.BucketVersioning{
            metadata: _metadata("{}-versioning".format(oxr.metadata.name))
            spec = {
                forProvider = {
                    region = params.region
                    bucketRef = {
                        name = bucketName
                    }
                    versioningConfiguration = {
                        status = "Enabled"
                    }
                }
            }
        }
    ]

items = _items