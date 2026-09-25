import boto3
import sys

def audit_account():
    iam = boto3.client('iam')
    users = iam.list_users().get('Users', [])
    print(f"[+] Auditing {len(users)} IAM User(s)...")

    non_mfa_users = []
    for u in users:
        username = u['UserName']
        mfa = iam.list_mfa_devices(UserName=username).get('MFADevices', [])
        if not mfa:
            non_mfa_users.append(username)
            print(f"  [ALERT] User '{username}' does NOT have MFA enabled!")
        else:
            print(f"  [OK] User '{username}' has MFA enabled.")

    if non_mfa_users:
        print(f"\n[X] Audit Failed: {len(non_mfa_users)} user(s) lack MFA.")
        sys.exit(1)
    print("\n[✓] Audit Passed: All users have MFA enabled.")

if __name__ == "__main__":
    audit_account()
