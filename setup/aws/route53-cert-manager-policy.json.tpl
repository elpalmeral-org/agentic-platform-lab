{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ConsultarCambios",
      "Effect": "Allow",
      "Action": "route53:GetChange",
      "Resource": "arn:aws:route53:::change/*"
    },
    {
      "Sid": "LocalizarZona",
      "Effect": "Allow",
      "Action": "route53:ListHostedZonesByName",
      "Resource": "*"
    },
    {
      "Sid": "LeerRegistrosDeLaZona",
      "Effect": "Allow",
      "Action": "route53:ListResourceRecordSets",
      "Resource": "arn:aws:route53:::hostedzone/${R53_ZONE_ID}"
    },
    {
      "Sid": "SoloTxtDelRetoAcme",
      "Effect": "Allow",
      "Action": "route53:ChangeResourceRecordSets",
      "Resource": "arn:aws:route53:::hostedzone/${R53_ZONE_ID}",
      "Condition": {
        "ForAllValues:StringEquals": {
          "route53:ChangeResourceRecordSetsRecordTypes": ["TXT"],
          "route53:ChangeResourceRecordSetsNormalizedRecordNames": ["_acme-challenge.${LAB_SUBDOMAIN}.${LAB_DOMAIN}"]
        }
      }
    }
  ]
}
