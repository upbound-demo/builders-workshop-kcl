import models.io.upbound.gcpm.storage.v1beta1 as gcpmstoragev1beta1

oxr = option("params").oxr # observed composite resource
params = oxr.spec.parameters

bucketName = "{}-bucket".format(oxr.metadata.name)

_metadata = lambda name: str -> any {
  {
    name = name
    annotations = {
      "krm.kcl.dev/composition-resource-name" = name
    }
  }
}

_items: [any] = [
    gcpmstoragev1beta1.Bucket{
        metadata: _metadata(bucketName)
        spec = {
            forProvider = {
                location = params.location
                versioning = {
                    enabled = params.versioning
                }
            }
        }
    },
    gcpmstoragev1beta1.BucketACL{
        metadata: _metadata("{}-encryption".format(oxr.metadata.name))
        spec = {
            forProvider = {
                bucketRef = {
                    name = bucketName
                }
                predefinedAcl = params.acl
            }
        }
    }
]

items = _items