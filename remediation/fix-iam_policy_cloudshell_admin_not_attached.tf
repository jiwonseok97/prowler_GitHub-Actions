# CloudShellFullAccess 정책이 이미 어디에도 attach되지 않은 경우
# aws_iam_policy_attachment은 empty result 에러를 발생시키므로
# 개별 리소스 타입으로 분리하여 처리
resource "aws_iam_group_policy_attachment" "remediation_detach_cloudshell_from_groups" {
  count      = 0
  group      = ""
  policy_arn = "arn:aws:iam::aws:policy/AWSCloudShellFullAccess"
}
