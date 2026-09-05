type GroupInvitationEmailInput = {
  groupName: string;
  memberName: string;
  memberRole?: string | null;
  invitationCode: string;
  expiresAt: Date;
  inviterName?: string | null;
  inviterRole?: string | null;
  groupCode?: string | null;
  groupType?: string | null;
  currency?: string | null;
  recipientEmail?: string | null;
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
  const inviterName = escapeHtml(input.inviterName?.trim() || "Group Admin");
  const inviterRole = escapeHtml(roleLabel(input.inviterRole || "GROUP_ADMIN"));
  const memberRole = escapeHtml(roleLabel(input.memberRole || "MEMBER"));
  const groupCode = escapeHtml(input.groupCode?.trim() || "Vikoplus Group");
  const groupType = escapeHtml(input.groupType?.trim() || "Savings Group");
  const currency = escapeHtml(input.currency?.trim() || "TZS");
  const recipientEmail = escapeHtml(
    input.recipientEmail?.trim() || input.memberName,
  );
  const expiresOn = formatDate(input.expiresAt);
  const dispatchedAt = formatDateTime(new Date());
  const subject = `You have been invited to ${input.groupName}`;
  const text = [
    `Hello ${input.memberName},`,
    `${input.inviterName?.trim() || "Group Admin"} has invited you to join ${input.groupName} on Vikoplus.`,
    `Invitation code: ${input.invitationCode}.`,
    "Sign in or create your Vikoplus account, then open My Groups and choose Join group.",
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
<body style="margin:0;padding:0;background-color:#ecf8f1;color:#1e293b;font-family:'Plus Jakarta Sans','Segoe UI',Roboto,Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased;">
  <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" style="background-color:#ecf8f1;">
    <tr>
      <td align="center" style="padding:28px 12px;">
        <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" style="max-width:620px;background-color:#ffffff;border:1px solid rgba(6,78,59,0.10);border-radius:28px;overflow:hidden;box-shadow:0 18px 40px rgba(2,44,34,0.08);">
          <tr>
            <td style="background:#084e3a;padding:30px 32px;color:#ffffff;">
              <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%">
                <tr>
                  <td align="left" valign="middle">
                    <table role="presentation" border="0" cellpadding="0" cellspacing="0">
                      <tr>
                        <td align="center" valign="middle" style="width:46px;height:46px;border-radius:16px;background-color:rgba(255,255,255,0.12);border:1px solid rgba(255,255,255,0.22);font-size:24px;font-weight:800;color:#ffffff;">V</td>
                        <td style="padding-left:14px;">
                          <div style="font-size:22px;font-weight:800;line-height:1;color:#ffffff;">Vikoplus</div>
                          <div style="font-size:11px;font-weight:800;letter-spacing:1.4px;text-transform:uppercase;color:#a7f3d0;padding-top:6px;">Chama &amp; Sacco Finance</div>
                        </td>
                      </tr>
                    </table>
                  </td>
                  <td align="right" valign="middle">
                    <span style="display:inline-block;padding:7px 12px;border-radius:999px;background-color:rgba(255,255,255,0.12);border:1px solid rgba(255,255,255,0.18);font-size:11px;font-weight:800;color:#d1fae5;">Group Invitation</span>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
          <tr>
            <td style="padding:34px 32px 30px 32px;">
              <div style="font-size:12px;font-weight:800;letter-spacing:1.2px;text-transform:uppercase;color:#065f46;">You're invited to join</div>
              <h1 style="margin:8px 0 12px 0;font-size:27px;line-height:1.24;color:#0f172a;font-weight:900;">${groupName}</h1>
              <p style="margin:0 0 24px 0;font-size:15px;line-height:1.7;color:#475569;">Hello <strong style="color:#0f172a;">${memberName}</strong>, you have been officially invited by <strong style="color:#0f172a;">${inviterName}</strong> (${inviterRole}) to become an active member of this trusted financial community.</p>

              <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" style="background-color:#eefaf4;border:1px solid rgba(5,150,105,0.22);border-radius:22px;margin-bottom:26px;">
                <tr>
                  <td style="padding:22px;">
                    <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%">
                      <tr>
                        <td valign="middle" style="width:58px;">
                          <div style="width:50px;height:50px;border-radius:16px;background-color:#ffffff;border:1px solid #d1fae5;text-align:center;line-height:50px;color:#047857;font-size:24px;font-weight:800;">G</div>
                        </td>
                        <td valign="middle">
                          <div style="font-size:16px;font-weight:900;color:#0f172a;">${groupName}</div>
                          <div style="font-size:12px;color:#64748b;padding-top:4px;">Group code: <span style="font-family:'JetBrains Mono','Courier New',monospace;font-weight:800;color:#065f46;">${groupCode}</span></div>
                        </td>
                        <td align="right" valign="middle">
                          <span style="display:inline-block;padding:7px 10px;border-radius:8px;background-color:#d1fae5;color:#065f46;font-size:12px;font-weight:800;">${groupType}</span>
                        </td>
                      </tr>
                    </table>

                    <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" style="margin-top:18px;border-top:1px solid rgba(16,185,129,0.22);padding-top:16px;">
                      <tr>
                        <td align="center" style="width:33.333%;padding:0 4px;">
                          <div style="background-color:rgba(255,255,255,0.88);border:1px solid #d1fae5;border-radius:14px;padding:14px 8px;">
                            <div style="font-size:10px;font-weight:800;color:#64748b;text-transform:uppercase;letter-spacing:.6px;">Role</div>
                            <div style="font-size:14px;font-weight:900;color:#0f172a;margin-top:4px;">${memberRole}</div>
                          </div>
                        </td>
                        <td align="center" style="width:33.333%;padding:0 4px;">
                          <div style="background-color:rgba(255,255,255,0.88);border:1px solid #d1fae5;border-radius:14px;padding:14px 8px;">
                            <div style="font-size:10px;font-weight:800;color:#64748b;text-transform:uppercase;letter-spacing:.6px;">Currency</div>
                            <div style="font-size:14px;font-weight:900;color:#0f172a;margin-top:4px;">${currency}</div>
                          </div>
                        </td>
                        <td align="center" style="width:33.333%;padding:0 4px;">
                          <div style="background-color:rgba(255,255,255,0.88);border:1px solid #d1fae5;border-radius:14px;padding:14px 8px;">
                            <div style="font-size:10px;font-weight:800;color:#64748b;text-transform:uppercase;letter-spacing:.6px;">Status</div>
                            <div style="font-size:14px;font-weight:900;color:#047857;margin-top:4px;">Invited</div>
                          </div>
                        </td>
                      </tr>
                    </table>
                  </td>
                </tr>
              </table>

              <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" style="border:2px dashed rgba(16,185,129,0.55);border-radius:22px;background-color:rgba(236,253,245,0.75);margin-bottom:26px;">
                <tr>
                  <td align="center" style="padding:22px 18px;">
                    <div style="font-size:12px;font-weight:800;color:#065f46;margin-bottom:8px;">Already have the Vikoplus mobile app installed?</div>
                    <div style="font-size:13px;line-height:1.5;color:#475569;margin-bottom:12px;">Open <strong style="color:#0f172a;">My Groups</strong>, tap <strong style="color:#0f172a;">Join group</strong>, and enter this invitation code:</div>
                    <div style="display:inline-block;background-color:#ffffff;border:1px solid #6ee7b7;border-radius:14px;padding:12px 18px;font-family:'JetBrains Mono','Courier New',monospace;font-size:22px;font-weight:900;color:#064e3b;letter-spacing:2px;box-shadow:0 2px 8px rgba(6,78,59,0.08);">${invitationCode}</div>
                    <div style="font-size:11px;color:#64748b;margin-top:10px;">Invitation expires ${escapeHtml(expiresOn)} EAT</div>
                  </td>
                </tr>
              </table>

              <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" style="background-color:#f8fafc;border:1px solid #e2e8f0;border-radius:18px;margin-bottom:24px;">
                <tr>
                  <td style="padding:20px;">
                    <div style="font-size:12px;font-weight:900;color:#334155;text-transform:uppercase;letter-spacing:.9px;margin-bottom:14px;">What happens when you accept?</div>
                    <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%">
                      <tr>
                        <td valign="top" style="width:28px;"><span style="display:inline-block;width:22px;height:22px;border-radius:999px;background-color:#d1fae5;color:#065f46;text-align:center;line-height:22px;font-size:12px;font-weight:900;">1</span></td>
                        <td style="font-size:13px;line-height:1.55;color:#475569;padding-bottom:10px;"><strong style="color:#0f172a;">Group access:</strong> You can view the group workspace and your member contribution records.</td>
                      </tr>
                      <tr>
                        <td valign="top" style="width:28px;"><span style="display:inline-block;width:22px;height:22px;border-radius:999px;background-color:#d1fae5;color:#065f46;text-align:center;line-height:22px;font-size:12px;font-weight:900;">2</span></td>
                        <td style="font-size:13px;line-height:1.55;color:#475569;padding-bottom:10px;"><strong style="color:#0f172a;">Transparent tracking:</strong> Contributions, dues, arrears, and approvals stay visible in one place.</td>
                      </tr>
                      <tr>
                        <td valign="top" style="width:28px;"><span style="display:inline-block;width:22px;height:22px;border-radius:999px;background-color:#d1fae5;color:#065f46;text-align:center;line-height:22px;font-size:12px;font-weight:900;">3</span></td>
                        <td style="font-size:13px;line-height:1.55;color:#475569;"><strong style="color:#0f172a;">Future services:</strong> You can access reminders, reports, and group loan workflows when enabled by the group.</td>
                      </tr>
                    </table>
                  </td>
                </tr>
              </table>

              <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%" style="background-color:#f8fafc;border:1px solid rgba(226,232,240,0.9);border-radius:14px;">
                <tr>
                  <td style="width:44px;padding:14px 0 14px 16px;">
                    <div style="width:36px;height:36px;border-radius:999px;background-color:#047857;color:#ffffff;text-align:center;line-height:36px;font-size:14px;font-weight:900;">${initials(input.inviterName || "Group Admin")}</div>
                  </td>
                  <td style="padding:14px 12px;">
                    <div style="font-size:13px;font-weight:800;color:#0f172a;">Invited by ${inviterName} &bull; ${inviterRole}</div>
                    <div style="font-size:11px;color:#64748b;margin-top:3px;">Administrator of ${groupName}</div>
                  </td>
                  <td align="right" style="padding:14px 16px;color:#047857;font-size:12px;font-weight:800;">Verified</td>
                </tr>
              </table>
            </td>
          </tr>
          <tr>
            <td style="background-color:rgba(241,245,249,0.92);border-top:1px solid rgba(226,232,240,0.9);padding:20px 32px;">
              <table role="presentation" border="0" cellpadding="0" cellspacing="0" width="100%">
                <tr>
                  <td style="font-size:11px;color:#64748b;line-height:1.55;width:50%;padding-right:8px;">
                    <strong style="color:#334155;">Recipient:</strong> ${recipientEmail}<br>
                    <strong style="color:#334155;">Invitation ID:</strong> ${invitationCode}
                  </td>
                  <td style="font-size:11px;color:#64748b;line-height:1.55;width:50%;padding-left:8px;">
                    <strong style="color:#334155;">Audit Status:</strong> Group Invitation Verified<br>
                    <strong style="color:#334155;">Dispatched:</strong> ${escapeHtml(dispatchedAt)} EAT
                  </td>
                </tr>
              </table>
              <p style="margin:14px 0 0 0;font-size:11px;line-height:1.55;color:#64748b;">Vikoplus will never ask you for your mobile banking PIN or account password via email. If you were not expecting this invitation, ignore this message or contact the group administrator.</p>
            </td>
          </tr>
          <tr>
            <td style="background-color:#04281e;color:rgba(167,243,208,0.82);padding:24px 32px;text-align:center;">
              <div style="font-size:12px;font-weight:800;color:#d1fae5;margin-bottom:10px;">Download Android App &bull; How Vikoplus Works &bull; Help Center</div>
              <div style="font-size:11px;line-height:1.55;color:rgba(52,211,153,0.72);">&copy; ${new Date().getFullYear()} Vikoplus Mutual Trust Financial Systems Ltd. All rights reserved.<br>Chama &amp; Sacco Double-Entry Ledger &bull; Dar es Salaam</div>
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

function formatDate(date: Date): string {
  return new Intl.DateTimeFormat("en-GB", {
    timeZone: "Africa/Dar_es_Salaam",
    dateStyle: "medium",
  }).format(date);
}

function formatDateTime(date: Date): string {
  return new Intl.DateTimeFormat("en-GB", {
    timeZone: "Africa/Dar_es_Salaam",
    dateStyle: "medium",
    timeStyle: "short",
  }).format(date);
}

function initials(value: string): string {
  const parts = value
    .trim()
    .split(/\s+/)
    .filter(Boolean)
    .slice(0, 2);
  return escapeHtml(parts.map((part) => part[0]?.toUpperCase() ?? "").join(""));
}

function roleLabel(value: string): string {
  return value
    .toLowerCase()
    .replaceAll("_", " ")
    .split(" ")
    .filter(Boolean)
    .map((part) => `${part[0]?.toUpperCase() ?? ""}${part.slice(1)}`)
    .join(" ");
}

function escapeHtml(value: string): string {
  return value
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#39;");
}
