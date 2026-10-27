{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ListarSoloElPrefijoPort",
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::${TF_STATE_BUCKET}",
      "Condition": {
        "StringLike": { "s3:prefix": ["port/*"] }
      }
    },
    {
      "Sid": "EstadoYBloqueoDePort",
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"],
      "Resource": "arn:aws:s3:::${TF_STATE_BUCKET}/port/*"
    }
  ]
}
