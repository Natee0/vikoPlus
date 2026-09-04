type VerificationEmailPurpose = "account_verification" | "password_reset";

type VerificationEmailInput = {
  code: string;
  destination: string;
  name?: string | null;
  purpose?: VerificationEmailPurpose;
};

export function verificationEmailTemplate(input: VerificationEmailInput): {
  subject: string;
  text: string;
  html: string;
} {
  const purpose = input.purpose ?? "account_verification";
  const digits = input.code.split("").map(escapeHtml);
  const requestedAt = new Intl.DateTimeFormat("en-GB", {
    timeZone: "Africa/Dar_es_Salaam",
    dateStyle: "medium",
    timeStyle: "short",
  }).format(new Date());
  const greeting = input.name?.trim()
    ? `Hello ${escapeHtml(input.name.trim())},`
    : "Hello,";
  const title =
    purpose === "password_reset"
      ? "Reset Your Vikoplus Password"
      : "Verify Your Account Identity";
  const subject =
    purpose === "password_reset"
      ? "Your Vikoplus password reset code"
      : "Your Vikoplus verification code";
  const context =
    purpose === "password_reset"
      ? "we received a request to reset the password for your Vikoplus account."
      : "we received a request to verify your Vikoplus account.";
  const destination = escapeHtml(input.destination);

  return {
    subject,
    text: `${greeting.replace(/<[^>]*>/g, "")} ${context} Your verification code is ${input.code}. It expires in 10 minutes. Never share this code with anyone.`,
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
                          <span style="display:block;color:#a7f3d0;font-size:11px;font-weight:700;text-transform:uppercase;letter-spacing:1.2px;">Group Finance Security</span>
                        </td>
                      </tr>
                    </table>
                  </td>
                  <td align="right" valign="middle">
                    <span style="display:inline-block;background-color:#287e65;color:#ffffff;font-size:11px;font-weight:700;padding:6px 12px;border-radius:20px;border:1px solid rgba(255,255,255,0.25);">OTP Verification</span>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
          <tr>
            <td style="padding:36px;">
              <h1 style="margin:0 0 10px 0;font-size:22px;font-weight:800;color:#141e1a;line-height:1.3;">${title}</h1>
              <p style="margin:0 0 24px 0;font-size:15px;color:#3f4944;line-height:1.6;">${greeting} ${context} Use the secure one-time code below to continue.</p>
              <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" style="margin-bottom:24px;">
                <tr>
                  <td align="center" style="background-color:#f8fcf9;border:1.5px dashed #0b6b4f;border-radius:18px;padding:24px 12px;">
                    <div style="font-size:12px;font-weight:800;color:#0b6b4f;text-transform:uppercase;letter-spacing:1px;margin-bottom:14px;">Your 6-digit one-time passcode</div>
                    <div>${digits
                      .map(
                        (digit) =>
                          `<span style="display:inline-block;width:42px;height:52px;line-height:52px;text-align:center;background-color:#ebf6ef;border:1.5px solid #a3d9b8;border-radius:12px;font-family:'Courier New',Courier,monospace;font-size:26px;font-weight:800;color:#0b6b4f;margin:0 3px;">${digit}</span>`,
                      )
                      .join("")}</div>
                    <div style="margin-top:16px;font-size:13px;color:#64748b;text-align:center;"><strong style="color:#d97706;">Valid for 10 minutes</strong> &bull; Never share this code with anyone.</div>
                  </td>
                </tr>
              </table>
              <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" style="background-color:#f1f5f9;border-radius:14px;margin-bottom:24px;">
                <tr>
                  <td style="padding:16px;font-size:13px;color:#334155;line-height:1.5;">
                    <strong style="color:#141e1a;">Didn't make this request?</strong> Ignore this email and contact your group administrator or Vikoplus support immediately.
                  </td>
                </tr>
              </table>
              <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" style="border-top:1px solid #e2e8f0;padding-top:18px;">
                <tr>
                  <td width="50%" valign="top" style="font-size:11px;color:#64748b;line-height:1.4;padding-right:8px;">
                    <span style="display:block;text-transform:uppercase;font-weight:700;color:#94a3b8;">Destination</span>
                    ${destination}
                  </td>
                  <td width="50%" valign="top" style="font-size:11px;color:#64748b;line-height:1.4;padding-left:8px;">
                    <span style="display:block;text-transform:uppercase;font-weight:700;color:#94a3b8;">Requested At</span>
                    ${escapeHtml(requestedAt)} EAT
                  </td>
                </tr>
              </table>
            </td>
          </tr>
          <tr>
            <td style="background-color:#ebf6ef;padding:24px 36px;border-top:1px solid #d8ebd9;text-align:center;">
              <p style="margin:0 0 8px 0;font-size:12px;font-weight:700;color:#52796f;">Vikoplus Mutual Trust Financial Systems</p>
              <p style="margin:0;font-size:11px;color:#94a3b8;line-height:1.6;">This is an automated transactional security alert. Replies to this email are not monitored.</p>
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
