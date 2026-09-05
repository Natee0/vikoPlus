type GroupInvitationEmailInput = {
  groupName: string;
  memberName: string;
  invitationCode: string;
  expiresAt: Date;
};

export function groupInvitationEmailTemplate(
  input: GroupInvitationEmailInput,
): {
  subject: string;
  text: string;
  html: string;
} {
  const groupName = escapeHtml(input.groupName);
  const memberName = escapeHtml(input.memberName);
  const invitationCode = escapeHtml(input.invitationCode);
  const expiresOn = new Intl.DateTimeFormat("en-GB", {
    timeZone: "Africa/Dar_es_Salaam",
    dateStyle: "medium",
  }).format(input.expiresAt);
  const subject = `You have been invited to ${input.groupName}`;
  const text = [
    `Hello ${input.memberName},`,
    `You have been invited to join ${input.groupName} on Vikoplus.`,
    `Invitation code: ${input.invitationCode}`,
    `This code expires on ${expiresOn}.`,
  ].join(" ");

  return {
    subject,
    text,
    html: `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta http-equiv="X-UA-Compatible" content="IE=edge">
  <meta name="x-apple-disable-message-reformatting">
  <title>${escapeHtml(subject)}</title>
</head>
<body style="margin:0;padding:30px 12px;background-color:#f1fcf5;color:#141e1a;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;">
  <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%">
    <tr>
      <td align="center" style="padding:10px 0 30px 0;">
        <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" style="max-width:580px;background-color:#ffffff;border-radius:24px;border:1px solid #d8ebd9;overflow:hidden;box-shadow:0 10px 30px rgba(11,107,79,0.08);">
          <tr>
            <td style="background-color:#0b6b4f;padding:32px 36px;">
              <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%">
                <tr>
                  <td align="left" valign="middle">
                    <table role="presentation" border="0" cellpadding="0" cellspacing="0">
                      <tr>
                        <td align="center" valign="middle" style="width:44px;height:44px;border-radius:12px;background-color:#287e65;color:#a7f3d0;font-size:24px;font-weight:800;">V</td>
                        <td style="padding-left:14px;">
                          <span style="display:block;color:#ffffff;font-size:22px;font-weight:800;line-height:1.1;">Vikoplus</span>
                          <span style="display:block;color:#a7f3d0;font-size:11px;font-weight:700;text-transform:uppercase;letter-spacing:1.2px;">Group Member Invitation</span>
                        </td>
                      </tr>
                    </table>
                  </td>
                  <td align="right" valign="middle">
                    <span style="display:inline-block;background-color:#287e65;color:#ffffff;font-size:11px;font-weight:700;padding:6px 12px;border-radius:20px;border:1px solid rgba(255,255,255,0.25);">Invite Code</span>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
          <tr>
            <td style="padding:36px;">
              <h1 style="margin:0 0 10px 0;font-size:22px;font-weight:800;color:#141e1a;line-height:1.3;">Join ${groupName}</h1>
              <p style="margin:0 0 24px 0;font-size:15px;color:#3f4944;line-height:1.6;">Hello ${memberName}, you have been added to <strong>${groupName}</strong>. Use the invitation code below after signing in to your Vikoplus account.</p>
              <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" style="margin-bottom:24px;">
                <tr>
                  <td align="center" style="background-color:#f8fcf9;border:1.5px dashed #0b6b4f;border-radius:18px;padding:24px 12px;">
                    <div style="font-size:12px;font-weight:800;color:#0b6b4f;text-transform:uppercase;letter-spacing:1px;margin-bottom:14px;">Your group invitation code</div>
                    <div style="display:inline-block;padding:14px 22px;background-color:#ebf6ef;border:1.5px solid #a3d9b8;border-radius:14px;font-family:'Courier New',Courier,monospace;font-size:26px;font-weight:800;color:#0b6b4f;letter-spacing:2px;">${invitationCode}</div>
                    <div style="margin-top:16px;font-size:13px;color:#64748b;text-align:center;"><strong style="color:#d97706;">Expires ${escapeHtml(expiresOn)}</strong> &bull; Keep this code private.</div>
                  </td>
                </tr>
              </table>
              <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" style="background-color:#f1f5f9;border-radius:14px;margin-bottom:24px;">
                <tr>
                  <td style="padding:16px;font-size:13px;color:#334155;line-height:1.5;">
                    <strong style="color:#141e1a;">Already have an account?</strong> Sign in, open My Groups, and choose Join group. New to Vikoplus? Create your account first, then enter this code.
                  </td>
                </tr>
              </table>
              <p style="margin:0;font-size:13px;color:#64748b;line-height:1.5;">If you were not expecting this invitation, ignore this email or contact the group administrator.</p>
            </td>
          </tr>
          <tr>
            <td style="background-color:#ebf6ef;padding:24px 36px;border-top:1px solid #d8ebd9;text-align:center;">
              <p style="margin:0 0 8px 0;font-size:12px;font-weight:700;color:#52796f;">Vikoplus Mutual Trust Financial Systems</p>
              <p style="margin:0;font-size:11px;color:#94a3b8;line-height:1.6;">This is an automated group invitation. Replies to this email are not monitored.</p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>`,
  };
}

function escapeHtml(value: string): string {
  return value
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}
