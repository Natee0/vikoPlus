import 'package:flutter/widgets.dart';

extension VikoplusTranslations on BuildContext {
  bool get isSwahili => Localizations.localeOf(this).languageCode == 'sw';

  String vt(String english) {
    if (!isSwahili) return english;
    return _swahili[english] ?? english;
  }

  String vtf(String english, Map<String, Object?> values) {
    var value = vt(english);
    for (final entry in values.entries) {
      value = value.replaceAll('{${entry.key}}', '${entry.value ?? ''}');
    }
    return value;
  }
}

const _swahili = <String, String>{
  'Vikoplus': 'Vikoplus',
  'Modern Financial Community': 'Jumuiya ya kisasa ya kifedha',
  'Manage your group\ncontributions with\ntransparency and ease.':
      'Simamia michango ya\nkikundi chako kwa\nuwazi na urahisi.',
  'Join thousands of communities trusting\nVikoplus for their shared financial goals.': 'Jiunge na jumuiya nyingi zinazotumia\nVikoplus kusimamia fedha za pamoja.',
  'Get started': 'Anza',
  'Sign in': 'Ingia',
  'Enter your phone/email and password.':
      'Weka namba ya simu/barua pepe na nenosiri.',
  'Verify account': 'Thibitisha akaunti',
  'Your account needs verification. Tap Verify account to continue.': 'Akaunti yako inahitaji uthibitisho. Bonyeza Thibitisha akaunti kuendelea.',
  'Verification session expired. Sign in again.':
      'Muda wa uthibitisho umeisha. Ingia tena.',
  'Cancel': 'Ghairi',
  'Close': 'Funga',
  'Confirm': 'Thibitisha',
  'Continue': 'Endelea',
  'Try Again': 'Jaribu tena',
  'Retry': 'Jaribu tena',
  'API connection is not configured.': 'Muunganisho wa API haujawekwa.',
  'This action is temporarily unavailable. Please try again later.':
      'Kitendo hiki hakipatikani kwa muda. Tafadhali jaribu tena baadaye.',
  'Bad gateway. Please try again.':
      'Kuna tatizo la lango la seva. Tafadhali jaribu tena.',
  'Service unavailable. Please try again.':
      'Huduma haipatikani kwa sasa. Tafadhali jaribu tena.',
  'Gateway timeout. Please try again.':
      'Seva imechelewa kujibu. Tafadhali jaribu tena.',
  'Server error. Please try again.':
      'Kuna tatizo la seva. Tafadhali jaribu tena.',
  'Check the details and try again.':
      'Kagua taarifa ulizoingiza kisha jaribu tena.',
  'Session expired. Please sign in again.':
      'Muda wa kipindi umeisha. Tafadhali ingia tena.',
  'You are not allowed to perform this action.':
      'Huna ruhusa ya kufanya kitendo hiki.',
  'The requested record was not found.': 'Rekodi uliyoomba haijapatikana.',
  'This record already exists.': 'Rekodi hii tayari ipo.',
  'Some details are invalid. Please check and try again.':
      'Baadhi ya taarifa si sahihi. Tafadhali kagua kisha jaribu tena.',
  'Too many requests. Please wait and try again.':
      'Maombi ni mengi mno. Tafadhali subiri kisha jaribu tena.',
  'Network request failed.': 'Ombi la mtandao limeshindwa.',
  'Something went wrong. Please try again.':
      'Kuna jambo halijaenda sawa. Tafadhali jaribu tena.',
  'Connection timed out. Check your internet and try again.':
      'Muunganisho umechelewa. Kagua intaneti yako kisha jaribu tena.',
  'Internet connection problem. Check your connection and try again.':
      'Kuna tatizo la intaneti. Kagua muunganisho wako kisha jaribu tena.',
  'Request cancelled. Please try again.':
      'Ombi limeghairiwa. Tafadhali jaribu tena.',
  'Secure connection failed. Please try again later.':
      'Muunganisho salama umeshindikana. Tafadhali jaribu tena baadaye.',
  'At least one field must be provided.': 'Weka angalau taarifa moja.',
  'Access plan code already exists.':
      'Msimbo wa mpango wa ufikiaji tayari upo.',
  'Access plan was not found.': 'Mpango wa ufikiaji haujapatikana.',
  'Reminder package code already exists.':
      'Msimbo wa kifurushi cha vikumbusho tayari upo.',
  'Invalid credentials.': 'Taarifa za kuingia si sahihi.',
  'Account identity is already registered or pending verification.':
      'Akaunti hii tayari imesajiliwa au inasubiri uthibitisho.',
  'OTP challenge could not be created.':
      'Imeshindikana kutengeneza uthibitisho wa OTP.',
  'Verification code expired or invalid.':
      'Msimbo wa uthibitisho umeisha muda au si sahihi.',
  'Too many verification attempts.': 'Umejaribu kuthibitisha mara nyingi mno.',
  'Invalid verification code.': 'Msimbo wa uthibitisho si sahihi.',
  'Verification session expired or invalid.':
      'Kipindi cha uthibitisho kimeisha muda au si sahihi.',
  'Account is already verified.': 'Akaunti tayari imethibitishwa.',
  'Password reset session expired.':
      'Kipindi cha kuweka upya nenosiri kimeisha.',
  'New password must be different from the current password.':
      'Nenosiri jipya lazima liwe tofauti na la sasa.',
  'Refresh token expired or invalid.':
      'Kipindi cha kuingia kimeisha au si sahihi.',
  'Phone or email is required.': 'Namba ya simu au barua pepe inahitajika.',
  'Image file is required.': 'Faili la picha linahitajika.',
  'Only JPG, PNG, and WebP images are allowed.':
      'Picha za JPG, PNG na WebP pekee ndizo zinaruhusiwa.',
  'Image must be 5MB or smaller.': 'Picha lazima iwe MB 5 au chini.',
  'Group billing access denied.':
      'Huna ruhusa ya kufikia malipo ya huduma ya kikundi.',
  'Invalid billing webhook signature': 'Sahihi ya webhook ya malipo si sahihi.',
  'Bearer token is required.': 'Tokeni ya kuingia inahitajika.',
  'Platform admin access is required.':
      'Ufikiaji wa msimamizi wa mfumo unahitajika.',
  'Invalid bearer token.': 'Tokeni ya kuingia si sahihi.',
  'Bearer token expired or invalid.':
      'Tokeni ya kuingia imeisha muda au si sahihi.',
  'Invalid bearer token signature.': 'Sahihi ya tokeni ya kuingia si sahihi.',
  'Account verification is required.': 'Uthibitisho wa akaunti unahitajika.',
  'This payment must be reviewed by the other payment reviewer role.':
      'Malipo haya lazima yakaguliwe na jukumu lingine la ukaguzi wa malipo.',
  'Payment cannot be approved from this state.':
      'Malipo haya hayawezi kuidhinishwa katika hali hii.',
  'Only pending payments can be rejected.':
      'Ni malipo yanayosubiri pekee yanaweza kukataliwa.',
  'Only pending payments can be corrected.':
      'Ni malipo yanayosubiri pekee yanaweza kuombewa marekebisho.',
  'Submit your own payment request for another reviewer to verify.':
      'Wasilisha ombi lako la malipo ili mkaguzi mwingine alithibitishe.',
  'Loan applications': 'Maombi ya mikopo',
  'Review guarantors, approve loans, and disburse funds':
      'Kagua wadhamini, idhinisha mikopo, na toa fedha',
  'Loan application not found.': 'Ombi la mkopo halijapatikana.',
  'Another treasurer must review your loan application.':
      'Mkaguzi mwingine lazima ahakiki ombi lako la mkopo.',
  'The applicant must be an active group member.':
      'Mwombaji lazima awe mwanachama hai wa kikundi.',
  'At least two active guarantors must confirm before approval.':
      'Angalau wadhamini wawili hai lazima wathibitishe kabla ya idhini.',
  'Only submitted applications can be approved.':
      'Ni maombi yaliyowasilishwa pekee yanaweza kuidhinishwa.',
  'Approved amount cannot exceed the requested amount.':
      'Kiasi kilichoidhinishwa hakiwezi kuzidi kiasi kilichoombwa.',
  'Applicant no longer meets the borrowing requirements.':
      'Mwombaji hakidhi tena masharti ya kukopa.',
  'Application has already been reviewed.': 'Ombi hili tayari limehakikiwa.',
  'Only submitted applications can be rejected.':
      'Ni maombi yaliyowasilishwa pekee yanaweza kukataliwa.',
  'Loan not found.': 'Mkopo haujapatikana.',
  'Only active loans can receive repayments.':
      'Ni mikopo hai pekee inaweza kupokea marejesho.',
  'Amount exceeds the balance remaining after pending repayments.':
      'Kiasi kimezidi salio lililobaki baada ya marejesho yanayosubiri.',
  'Guarantee request is unavailable or already answered.':
      'Ombi la udhamini halipatikani au tayari limejibiwa.',
  'Repayment not found.': 'Marejesho hayajapatikana.',
  'Another treasurer must verify your repayment.':
      'Mkaguzi mwingine lazima athibitishe marejesho yako.',
  'Repayment has already been reviewed.': 'Marejesho haya tayari yamehakikiwa.',
  'Repayment exceeds the active loan balance.':
      'Marejesho yamezidi salio la mkopo hai.',
  'Add another group admin before changing this admin role.': 'Ongeza msimamizi mwingine wa kikundi kabla ya kubadilisha jukumu la msimamizi huyu.',
  'Choose Group': 'Chagua kikundi',
  'Home': 'Nyumbani',
  'History': 'Historia',
  'Payments': 'Malipo',
  'Account': 'Akaunti',
  'Loans': 'Mikopo',
  'Notifications': 'Taarifa',
  'No notifications': 'Hakuna taarifa',
  'Vikoplus group alerts': 'Taarifa za vikundi vya Vikoplus',
  'Payment, loan, reminder, and group activity alerts.':
      'Taarifa za malipo, mikopo, vikumbusho na shughuli za kikundi.',
  'Important group updates will appear here.':
      'Taarifa muhimu za kikundi zitaonekana hapa.',
  'Could not load notifications.': 'Taarifa hazijapakiwa.',
  'Reminder Centre': 'Kituo cha vikumbusho',
  'Campaign Details': 'Maelezo ya kampeni',
  'Open a group to view reminders.': 'Fungua kikundi ili kuona vikumbusho.',
  'Could not load reminders. Please try again.':
      'Vikumbusho havijapakiwa. Tafadhali jaribu tena.',
  'Campaign not found in this group.':
      'Kampeni haijapatikana kwenye kikundi hiki.',
  'Channel: {value}': 'Njia: {value}',
  'Recipients: {value}': 'Wapokeaji: {value}',
  'Sent: {value}': 'Imetumwa: {value}',
  'Not sent': 'Haijatumwa',
  'Send reminder': 'Tuma kikumbusho',
  'Send Reminder': 'Tuma kikumbusho',
  'Channel': 'Njia ya kutuma',
  'Message': 'Ujumbe',
  'Use Template': 'Tumia kiolezo',
  'Write reminder message': 'Andika ujumbe wa kikumbusho',
  'Campaigns ({count})': 'Kampeni ({count})',
  'No campaigns sent yet.': 'Hakuna kampeni iliyotumwa bado.',
  '{channel} - {count} recipients': '{channel} - wapokeaji {count}',
  'Member Portal': 'Ukurasa wa mwanachama',
  'Welcome to your group': 'Karibu kwenye kikundi chako',
  'Your membership is active. Start with your first contribution.':
      'Uanachama wako uko hai. Anza kwa mchango wako wa kwanza.',
  'Make first contribution': 'Lipa mchango wa kwanza',
  'Review profile': 'Kagua wasifu',
  'My Contributions': 'Michango yangu',
  'Select a group to view your contributions.':
      'Chagua kikundi ili kuona michango yako.',
  'Could not load contributions. Please try again.':
      'Michango haijapakiwa. Tafadhali jaribu tena.',
  'Total paid': 'Jumla iliyolipwa',
  'Outstanding': 'Deni',
  'Contribution History': 'Historia ya michango',
  'No contribution obligations are due.':
      'Hakuna michango inayodaiwa kwa sasa.',
  'Member roles': 'Majukumu ya wanachama',
  'Assign chairperson, treasurer, secretary and member access':
      'Panga mwenyekiti, mweka hazina, katibu na ufikiaji wa mwanachama',
  'Currency and fees': 'Sarafu na ada',
  'TZS defaults, platform access and messaging charges':
      'Sarafu ya TZS, ada za mfumo na gharama za ujumbe',
  'Contribution setup': 'Mipangilio ya michango',
  'Set joining fee, membership fee and payment rules':
      'Weka kiingilio, ada ya uanachama na kanuni za malipo',
  'Historical records': 'Kumbukumbu za zamani',
  'Import previous group contributions and old ledgers':
      'Ingiza michango ya zamani na leja za awali',
  'Contribution penalties': 'Faini za michango',
  'Late-fee rules and grace periods': 'Kanuni za faini na muda wa nyongeza',
  'Audit logs': 'Kumbukumbu za ukaguzi',
  'Payment, role and subscription history':
      'Historia ya malipo, majukumu na usajili',
  'Admin Settings': 'Mipangilio ya msimamizi',
  'App Settings': 'Mipangilio ya programu',
  'Compact dashboard': 'Dashibodi fupi',
  'Show denser cards for frequent administrators.':
      'Onyesha kadi fupi kwa wasimamizi wanaotumia mara kwa mara.',
  'Use device language': 'Tumia lugha ya kifaa',
  'Keep English and Swahili-ready text aligned.':
      'Linganisha maandishi ya Kiingereza na Kiswahili.',
  'Language': 'Lugha',
  'Choose English or Swahili': 'Chagua Kiingereza au Kiswahili',
  'Security': 'Usalama',
  'Change security PIN': 'Badili PIN ya usalama',
  'Protect approvals and group administration actions':
      'Linda idhini na shughuli za usimamizi wa kikundi',
  'Require PIN for payment approvals': 'Hitaji PIN kwa idhini za malipo',
  'Treasurer and admin actions ask for extra confirmation.':
      'Vitendo vya mweka hazina na msimamizi vitahitaji uthibitisho zaidi.',
  'Change PIN': 'Badili PIN',
  'Current PIN': 'PIN ya sasa',
  'New PIN': 'PIN mpya',
  'Confirm PIN': 'Thibitisha PIN',
  'Update PIN': 'Sasisha PIN',
  'Notification Preferences': 'Mapendeleo ya taarifa',
  'Payment confirmations': 'Uthibitisho wa malipo',
  'Notify me when receipts are created.': 'Niarifu risiti zinapotengenezwa.',
  'Contribution reminders': 'Vikumbusho vya michango',
  'Receive reminders before and after due dates.':
      'Pokea vikumbusho kabla na baada ya tarehe za malipo.',
  'Role changes': 'Mabadiliko ya majukumu',
  'Alert members when their access changes.':
      'Waarifu wanachama ufikiaji wao unapobadilika.',
  'Member Roles': 'Majukumu ya wanachama',
  'The chairperson/admin assigns these roles when inviting or adding members.': 'Mwenyekiti au msimamizi hupanga majukumu haya anapoalika au kuongeza wanachama.',
  'Audit Logs': 'Kumbukumbu za ukaguzi',
  'Select a group to view audit logs.':
      'Chagua kikundi ili kuona kumbukumbu za ukaguzi.',
  'Could not load audit logs.': 'Kumbukumbu za ukaguzi hazijapakiwa.',
  'No audit logs yet': 'Hakuna kumbukumbu za ukaguzi bado',
  'Group administration activity will appear here.':
      'Shughuli za usimamizi wa kikundi zitaonekana hapa.',
  'Currency & Fees': 'Sarafu na ada',
  'Primary currency': 'Sarafu kuu',
  'Primary Currency': 'Sarafu kuu',
  'Group access': 'Ufikiaji wa kikundi',
  'SMS reminders': 'Vikumbusho vya SMS',
  'WhatsApp reminders': 'Vikumbusho vya WhatsApp',
  'Manage group rules, billing controls and admin access.':
      'Simamia kanuni za kikundi, bili na ufikiaji wa msimamizi.',
  'Security PIN is enabled for sensitive group actions.':
      'PIN ya usalama imewashwa kwa vitendo nyeti vya kikundi.',
  'Payment Rules': 'Kanuni za malipo',
  'Allow partial payments': 'Ruhusu malipo ya sehemu',
  'Enable late penalties': 'Washa faini za kuchelewa',
  'One charge per overdue contribution, after the grace period. Applies to future dues.': 'Tozo moja kwa mchango uliochelewa baada ya muda wa nyongeza. Hutumika kwa madeni yajayo.',
  'Penalty amount': 'Kiasi cha faini',
  'Grace period (days)': 'Muda wa nyongeza (siku)',
  'Save Rules': 'Hifadhi kanuni',
  'Payment rules saved.': 'Kanuni za malipo zimehifadhiwa.',
  'Enter a valid amount and grace period (0-365 days).':
      'Weka kiasi sahihi na muda wa nyongeza (siku 0-365).',
  'Configure Contributions': 'Weka michango',
  'Joining Fee': 'Kiingilio',
  'Require members to pay a fee upon joining.':
      'Wanachama walipe ada wanapojiunga.',
  'Joining Fee Amount': 'Kiasi cha kiingilio',
  'Membership Fee': 'Ada ya uanachama',
  'Set the recurring membership fee for every member.':
      'Weka ada ya uanachama inayojirudia kwa kila mwanachama.',
  'Membership Fee Amount': 'Kiasi cha ada ya uanachama',
  'Membership Fee Cycle': 'Mzunguko wa ada ya uanachama',
  'Membership Fee Due Day': 'Siku ya kulipa ada ya uanachama',
  'Member Contributions': 'Michango ya wanachama',
  'Set the normal contribution amount and how often members contribute.':
      'Weka kiasi cha kawaida cha mchango na mara za kuchangia.',
  'Contribution Amount': 'Kiasi cha mchango',
  'Contribution Cycle': 'Mzunguko wa mchango',
  'Due Schedule': 'Ratiba ya malipo',
  'Every day': 'Kila siku',
  '{day} of each cycle': '{day} ya kila mzunguko',
  'Due {day} of each cycle': 'Malipo: {day} ya kila mzunguko',
  'Due Day': 'Siku ya malipo',
  'Group payments stay manual. Members submit requests and the treasurer confirms receipt.': 'Malipo ya kikundi hubaki ya mkono. Wanachama hutuma maombi na mweka hazina huthibitisha kupokea.',
  'Allow Partial Payments': 'Ruhusu malipo ya sehemu',
  'Members can pay their contribution in installments.':
      'Wanachama wanaweza kulipa mchango kwa awamu.',
  'Auto Allocate Payments': 'Gawa malipo kiotomatiki',
  'Apply payments to oldest unpaid periods first.':
      'Tumia malipo kwenye vipindi vya zamani visivyolipwa kwanza.',
  'Joining fee': 'Kiingilio',
  'Membership fee': 'Ada ya uanachama',
  'Member contribution': 'Mchango wa mwanachama',
  'Disabled': 'Imezimwa',
  'Weekly Due Days': 'Siku za wiki za kulipa',
  'Import historical records': 'Ingiza kumbukumbu za zamani',
  'Historical group data': 'Taarifa za zamani za kikundi',
  'Admins and secretaries can add previous payments one by one or import them in bulk.': 'Wasimamizi na makatibu wanaweza kuongeza malipo ya zamani mmoja mmoja au kuyaingiza kwa pamoja.',
  'Create a group before setting contributions.':
      'Unda kikundi kabla ya kuweka michango.',
  'Enter valid contribution amounts.': 'Weka kiasi sahihi cha michango.',
  'Monthly': 'Kila mwezi',
  'Quarterly': 'Kila robo mwaka',
  'Yearly': 'Kila mwaka',
  'Daily': 'Kila siku',
  'Weekly': 'Kila wiki',
  'Monday': 'Jumatatu',
  'Tuesday': 'Jumanne',
  'Wednesday': 'Jumatano',
  'Thursday': 'Alhamisi',
  'Friday': 'Ijumaa',
  'Saturday': 'Jumamosi',
  'Sunday': 'Jumapili',
  'Welcome to\n{groupName}': 'Karibu\n{groupName}',
  'Your group is ready. Complete the setup below to start tracking contributions and managing members.': 'Kikundi chako kiko tayari. Kamilisha mipangilio hapa chini ili kuanza kufuatilia michango na kusimamia wanachama.',
  'Add First Member': 'Ongeza mwanachama wa kwanza',
  'Setup Progress': 'Maendeleo ya mipangilio',
  '{done} of 5 steps completed': 'Hatua {done} kati ya 5 zimekamilika',
  'Group Created': 'Kikundi kimeundwa',
  'Financial Year Set': 'Mwaka wa fedha umewekwa',
  'Loan Requests': 'Maombi ya mikopo',
  'No requests awaiting your response.':
      'Hakuna maombi yanayosubiri jibu lako.',
  'Confirm guarantee response': 'Thibitisha jibu la udhamini',
  'Verify repayment': 'Thibitisha marejesho',
  'Respond to {name}\'s guarantee request for {amount}?':
      'Jibu ombi la udhamini la {name} kwa {amount}?',
  'Confirm repayment from {name}.': 'Thibitisha marejesho kutoka kwa {name}.',
  'Guarantee request': 'Ombi la udhamini',
  'Repayment verification': 'Uthibitisho wa marejesho',
  'Guarantees and repayment requests': 'Dhamana na maombi ya marejesho',
  'Active Loans': 'Mikopo hai',
  'Applications': 'Maombi',
  'Apply for New Loan': 'Omba mkopo mpya',
  'Loan requests & history': 'Maombi na historia ya mikopo',
  'All ({count})': 'Yote ({count})',
  'Apply for Loan': 'Omba mkopo',
  'Loan Amount': 'Kiasi cha mkopo',
  'Choose a group first': 'Chagua kikundi kwanza',
  'Loans are managed inside a group.': 'Mikopo husimamiwa ndani ya kikundi.',
  'Open Groups': 'Fungua vikundi',
  'No active loans': 'Hakuna mikopo hai',
  'Approved loans will appear here.': 'Mikopo iliyoidhinishwa itaonekana hapa.',
  'No loan applications found.': 'Hakuna maombi ya mkopo yaliyopatikana.',
  'AVAILABLE BORROWING POWER': 'KIASI UNACHOWEZA KUKOPA',
  'Credit Limit: {amount}': 'Kikomo cha mkopo: {amount}',
  'Due {date}': 'Mwisho {date}',
  'Paid: {amount}': 'Imelipwa: {amount}',
  'Remaining: {amount}': 'Imebaki: {amount}',
  'Make Payment': 'Fanya malipo',
  'Eligibility & Requirements': 'Vigezo na mahitaji',
  'Review Application': 'Hakiki ombi',
  'View status': 'Angalia hali',
  'Approve & Disburse Funds': 'Idhinisha na toa fedha',
  'Reject Application': 'Kataa ombi',
  'Pending Review': 'Inasubiri ukaguzi',
  'Guarantor Pending': 'Inasubiri mdhamini',
  'Loan Details': 'Maelezo ya mkopo',
  'Requested Amount': 'Kiasi kilichoombwa',
  'Purpose': 'Sababu',
  'Repayment Term': 'Muda wa kurejesha',
  'Estimated Total': 'Jumla inayokadiriwa',
  'Interest Rate': 'Riba',
  '1.5% / month': '1.5% / mwezi',
  'Guarantor Verification': 'Uthibitisho wa wadhamini',
  'Confirmed': 'Imethibitishwa',
  'Declined': 'Imekataliwa',
  'Treasurer Review': 'Ukaguzi wa mweka hazina',
  'Comments, modified amount, or disbursement notes...':
      'Maoni, kiasi kilichorekebishwa, au maelezo ya kutoa fedha...',
  '{confirmed}/{required} guarantors confirmed':
      'Wadhamini {confirmed}/{required} wamethibitisha',
  'Submitted': 'Limewasilishwa',
  'Disbursed': 'Limetolewa',
  'Rejected': 'Limekataliwa',
  'Loan Purpose': 'Sababu ya mkopo',
  'School fees': 'Ada za shule',
  'Emergency': 'Dharura',
  'Business': 'Biashara',
  'Agriculture': 'Kilimo',
  '{months} Months': 'Miezi {months}',
  'Decline': 'Kataa',
  'Accept': 'Kubali',
  'Received': 'Imepokelewa',
  'your group': 'kikundi chako',
  'Select a group to view dues and arrears.':
      'Chagua kikundi ili kuona madeni yako.',
  'Could not load outstanding dues.': 'Madeni hayajapakiwa.',
  'Dues & Arrears': 'Madeni na malimbikizo',
  'Manage your outstanding group fees.':
      'Simamia ada zako za kikundi ambazo bado hujalipa.',
  'Outstanding Contributions': 'Michango inayodaiwa',
  'You do not have outstanding dues.': 'Huna deni lolote kwa sasa.',
  'Already paid?': 'Tayari umelipa?',
  'Notify the treasurer for a payment you have already sent. The treasurer will verify and update your record.': 'Mtaarifu mweka hazina kuhusu malipo uliyotuma. Atathibitisha na kusasisha rekodi yako.',
  'Pay selected dues': 'Lipa madeni yaliyochaguliwa',
  'Member': 'Mwanachama',
  'My Profile': 'Wasifu wangu',
  'Manage profile': 'Simamia wasifu',
  'Seek loan': 'Omba mkopo',
  'Apply for support or track your loan requests':
      'Omba msaada au fuatilia maombi yako ya mkopo',
  'Group members': 'Wanachama wa kikundi',
  'View fellow members in this group': 'Angalia wanachama wenzako wa kikundi',
  'Update language': 'Badili lugha',
  'Choose Kiswahili or English': 'Chagua Kiswahili au Kiingereza',
  'Switch groups': 'Badili vikundi',
  'Open another group, create one, or join by code':
      'Fungua kikundi kingine, unda kipya, au jiunge kwa msimbo',
  'Scheduled': 'Imepangwa',
  'Joined group': 'Ulijiunga na kikundi',
  'Membership confirmed': 'Uanachama umethibitishwa',
  'Today': 'Leo',
  'First contribution due': 'Mchango wa kwanza unaofuata',
  'Contribution Summary': 'Muhtasari wa michango',
  'Total Paid': 'Jumla iliyolipwa',
  'Outstanding Balance': 'Salio linalodaiwa',
  'Next Due': 'Malipo yanayofuata',
  'Annual Goal Progress': 'Maendeleo ya mwaka',
  'Make a Payment': 'Fanya malipo',
  'View dues': 'Angalia madeni',
  'Cleared': 'Imekamilika',
  '{count} paid': '{count} zimelipwa',
  'Select a group to load your contribution summary.':
      'Chagua kikundi ili kupakia muhtasari wa michango yako.',
  'Could not load your contribution summary.':
      'Muhtasari wa michango yako haujapakiwa.',
  'User ID': 'Kitambulisho cha mtumiaji',
  'Not signed in': 'Hujaingia',
  'Preferred Language': 'Lugha unayopendelea',
  'Group': 'Kikundi',
  'None': 'Hakuna',
  'Status': 'Hali',
  'New user': 'Mtumiaji mpya',
  'Select at least one contribution.': 'Chagua angalau mchango mmoja.',
  'Select Contribution': 'Chagua mchango',
  'Choose what you want to pay.': 'Chagua unachotaka kulipa.',
  'Select a group before making a contribution.':
      'Chagua kikundi kabla ya kulipa mchango.',
  'Could not load your contributions.': 'Michango yako haijapakiwa.',
  'Nothing Due': 'Hakuna deni',
  'Your current contribution obligations are fully paid.':
      'Michango yako ya sasa imelipwa yote.',
  'Selected items': 'Vipengee vilivyochaguliwa',
  'Payment purpose': 'Sababu ya malipo',
  'Payment Method': 'Njia ya malipo',
  'Mobile money': 'Malipo ya simu',
  'M-Pesa, Tigo Pesa, Airtel Money': 'M-Pesa, Tigo Pesa, Airtel Money',
  'Bank transfer': 'Hamisho la benki',
  'Pay from a bank account': 'Lipa kupitia akaunti ya benki',
  'Cash to treasurer': 'Pesa taslimu kwa mweka hazina',
  'Treasurer records and verifies manually':
      'Mweka hazina hurekodi na kuthibitisha kwa mkono',
  'Review Payment': 'Kagua malipo',
  'Select a group before submitting payment.':
      'Chagua kikundi kabla ya kutuma malipo.',
  'Select contribution items before submitting.':
      'Chagua michango kabla ya kutuma malipo.',
  'Payment request was not submitted. Please try again.':
      'Ombi la malipo halijatumwa. Tafadhali jaribu tena.',
  'Cash payment': 'Malipo taslimu',
  'Submit this contribution for treasurer verification.':
      'Tuma mchango huu uthibitishwe na mweka hazina.',
  'Selected group': 'Kikundi kilichochaguliwa',
  'Payment method': 'Njia ya malipo',
  'Pending treasurer review': 'Inasubiri uhakiki wa mweka hazina',
  'Submitting': 'Inatuma',
  'Submit for verification': 'Tuma kwa uthibitisho',
  'Payment Submitted': 'Malipo yametumwa',
  'Your contribution request is waiting for treasurer verification. A receipt will be created after approval.': 'Ombi lako la mchango linasubiri uthibitisho wa mweka hazina. Risiti itatengenezwa baada ya kuidhinishwa.',
  'Your contribution request is waiting for secretary or treasurer verification. A receipt will be created after approval.': 'Ombi lako la mchango linasubiri uthibitisho wa katibu au mweka hazina. Risiti itatengenezwa baada ya kuidhinishwa.',
  'Request ID': 'Namba ya ombi',
  'Pending': 'Inasubiri',
  'Pending verification': 'Inasubiri uthibitisho',
  'Total Amount': 'Jumla ya kiasi',
  'View Contributions': 'Angalia michango',
  'Share': 'Shiriki',
  'Record New': 'Rekodi mpya',
  'Return to Dashboard': 'Rudi kwenye dashibodi',
  'Digital Receipt': 'Risiti ya kidigitali',
  'More options': 'Chaguo zaidi',
  'Receipt not available yet': 'Risiti bado haijapatikana',
  'A receipt will be created after the treasurer approves this payment.':
      'Risiti itatengenezwa baada ya mweka hazina kuidhinisha malipo haya.',
  'Select a group': 'Chagua kikundi',
  'Open a group before viewing receipts.':
      'Fungua kikundi kabla ya kuona risiti.',
  'Could not load this receipt. Please try again.':
      'Risiti hii haijapakiwa. Tafadhali jaribu tena.',
  'Go Back': 'Rudi nyuma',
  'Reference No': 'Namba ya kumbukumbu',
  'Date & Time': 'Tarehe na muda',
  'Group Name': 'Jina la kikundi',
  'Contribution Type': 'Aina ya mchango',
  'Monthly Contribution': 'Mchango wa mwezi',
  'Member Name': 'Jina la mwanachama',
  'Amount': 'Kiasi',
  'Transaction Fee': 'Ada ya muamala',
  'Total': 'Jumla',
  'Share Receipt': 'Shiriki risiti',
  'Download PDF': 'Pakua PDF',
  'Payment Confirmed': 'Malipo yamethibitishwa',
  'This is an automated receipt for your records.\nPlease contact your group admin for any queries.': 'Hii ni risiti ya moja kwa moja kwa kumbukumbu zako.\nWasiliana na msimamizi wa kikundi kwa maswali yoyote.',
  'Other': 'Nyingine',
  'Cash': 'Pesa taslimu',
  'Mobile Money': 'Malipo ya simu',
  'Bank Transfer': 'Hamisho la benki',
  'Monthly Club Dues': 'Ada za mwezi za kikundi',
  'Paid': 'Imelipwa',
  'Due': 'Inadaiwa',
  'Collection date': 'Tarehe ya ukusanyaji',
  'Upcoming': 'Inakuja',
  'No contributions are due yet. Upcoming items will activate on their collection date.': 'Hakuna michango inayodaiwa bado. Michango inayofuata itafunguka siku yake ya ukusanyaji ikifika.',
  'Reports': 'Ripoti',
  'Available reports': 'Ripoti zilizopo',
  'Outstanding contributions': 'Michango inayodaiwa',
  'Members and periods still due': 'Wanachama na vipindi vyenye madeni',
  'Member contribution analysis': 'Uchambuzi wa michango ya wanachama',
  'Joining fee, monthly dues, total and percentage':
      'Kiingilio, ada za mwezi, jumla na asilimia',
  'Export files': 'Pakua faili',
  'Selected format is managed in report filters':
      'Muundo uliochaguliwa unasimamiwa kwenye vichujio vya ripoti',
  'Select a group to load reports.': 'Chagua kikundi ili kupakia ripoti.',
  'Could not load contribution report.': 'Ripoti ya michango haijapakiwa.',
  'Joining': 'Kiingilio',
  'Recurring': 'Inayojirudia',
  'Outstanding obligations': 'Madeni yaliyobaki',
  'Export format': 'Muundo wa faili',
  'CSV': 'CSV',
  'PDF': 'PDF',
  'All members': 'Wanachama wote',
  'Outstanding only': 'Wenye madeni tu',
  'Cleared only': 'Waliomaliza tu',
  'Could not load financial years.': 'Miaka ya fedha haijapakiwa.',
  'Outstanding report': 'Ripoti ya madeni',
  'Select a group to view reports.': 'Chagua kikundi ili kuona ripoti.',
  'Could not load outstanding report.': 'Ripoti ya madeni haijapakiwa.',
  '{count} members still have dues': 'Wanachama {count} bado wana madeni',
  'All current contribution obligations are paid.':
      'Michango yote ya sasa imelipwa.',
  'Member analysis': 'Uchambuzi wa wanachama',
  'Contribution breakdown': 'Mchanganuo wa michango',
  'Could not load member analysis.': 'Uchambuzi wa wanachama haujapakiwa.',
  'No contribution obligations are available yet.':
      'Hakuna michango iliyopangwa bado.',
  'My Groups': 'Vikundi vyangu',
  'Refresh groups': 'Onyesha upya vikundi',
  'Choose a group to open, create a new group, or join one using an invitation.':
      'Chagua kikundi cha kufungua, unda kikundi kipya, au jiunge kwa mwaliko.',
  'Create group': 'Unda kikundi',
  'Create Group': 'Unda kikundi',
  'Join group': 'Jiunge na kikundi',
  'Groups you can access': 'Vikundi unavyoweza kufikia',
  'No groups yet': 'Bado hakuna vikundi',
  'Create a group or join one with an invitation code.':
      'Unda kikundi au jiunge na kikundi kwa msimbo wa mwaliko.',
  'Try again': 'Jaribu tena',
  'Open a group before managing members.':
      'Fungua kikundi kabla ya kusimamia wanachama.',
  'Invite members': 'Alika wanachama',
  'Add member manually': 'Ongeza mwanachama kwa mkono',
  'Add/Invite Member': 'Ongeza/Alika mwanachama',
  'Create a member record and send the invitation automatically':
      'Tengeneza taarifa ya mwanachama na tuma mwaliko kiotomatiki',
  'Share a role-based invitation code, link, SMS or WhatsApp':
      'Shiriki msimbo, kiungo, SMS au WhatsApp ya mwaliko wenye jukumu',
  'Create a member record and assign their group role':
      'Tengeneza rekodi ya mwanachama na mpangie jukumu kwenye kikundi',
  'Search members...': 'Tafuta wanachama...',
  'All': 'Wote',
  'Active': 'Hai',
  'Suspended': 'Amesimamishwa',
  'Removed': 'Ameondolewa',
  'Fully paid': 'Amemaliza kulipa',
  'Total members': 'Jumla ya wanachama',
  'Current role': 'Jukumu la sasa',
  'Group Admin': 'Msimamizi wa kikundi',
  'Treasurer': 'Mweka hazina',
  'Secretary': 'Katibu',
  'No members match these filters.':
      'Hakuna mwanachama anayelingana na vichujio hivi.',
  'No members yet': 'Hakuna wanachama bado',
  'Add the first member or invite members to join this group.': 'Ongeza mwanachama wa kwanza au alika wanachama wajiunge na kikundi hiki.',
  'Open a group before adding members.':
      'Fungua kikundi kabla ya kuongeza wanachama.',
  'Only the group admin can add members and send invitations.': 'Msimamizi wa kikundi pekee ndiye anaweza kuongeza wanachama na kutuma mialiko.',
  'Enter the member full name.': 'Weka jina kamili la mwanachama.',
  'Enter a phone number or email address to send the invitation.':
      'Weka namba ya simu au barua pepe ili kutuma mwaliko.',
  'Member invitation sent.': 'Mwaliko wa mwanachama umetumwa.',
  'Add Member': 'Ongeza mwanachama',
  'Personal Information': 'Taarifa binafsi',
  'Full Name': 'Jina kamili',
  'Enter full name': 'Weka jina kamili',
  'Phone Number': 'Namba ya simu',
  '(Required if no email)': '(Inahitajika kama hakuna barua pepe)',
  'Email Address': 'Barua pepe',
  '(Required if no phone)': '(Inahitajika kama hakuna simu)',
  'Membership Details': 'Maelezo ya uanachama',
  'Assign the role this member will use in the group.':
      'Panga jukumu ambalo mwanachama huyu atatumia kwenye kikundi.',
  'Member Number': 'Namba ya mwanachama',
  'MBR-000001 (automatic if empty)':
      'MBR-000001 (huundwa yenyewe ukiiacha wazi)',
  'Settings & Invitations': 'Mipangilio na mialiko',
  'Require Joining Fee': 'Hitaji kiingilio',
  'Create the joining fee obligation for this member.':
      'Tengeneza deni la kiingilio kwa mwanachama huyu.',
  'Saving creates an invited member record, generates a join code, and sends it by SMS or email.': 'Ukihifadhi, rekodi ya mwalikwa hutengenezwa, msimbo wa kujiunga hutolewa, na kutumwa kwa SMS au barua pepe.',
  'Sending': 'Inatuma',
  'Send Invite': 'Tuma mwaliko',
  'Open a group before inviting members.':
      'Fungua kikundi kabla ya kualika wanachama.',
  'Enter a phone number or email.': 'Weka namba ya simu au barua pepe.',
  'Invite Members': 'Alika wanachama',
  'Share this code or link with new members. The chairperson/admin chooses the role attached to this invitation.': 'Shiriki msimbo au kiungo hiki na wanachama wapya. Mwenyekiti au msimamizi huchagua jukumu la mwaliko huu.',
  'Phone number or email': 'Namba ya simu au barua pepe',
  'Generating': 'Inatengeneza',
  'Generate Invitation': 'Tengeneza mwaliko',
  'Copy Code': 'Nakili msimbo',
  'Enter your phone number or email.': 'Weka namba yako ya simu au barua pepe.',
  'Forgot Password': 'Umesahau nenosiri',
  'Forgot Password?': 'Umesahau nenosiri?',
  "Enter your registered details and we'll send a secure one-time verification code.":
      'Weka taarifa ulizosajili na tutakutumia msimbo salama wa mara moja.',
  'Group contributions and account access remain secure.':
      'Michango ya kikundi na ufikiaji wa akaunti hubaki salama.',
  'Send Reset Code': 'Tuma msimbo wa kuweka upya',
  'Remember password? ': 'Unakumbuka nenosiri? ',
  'Reset session expired. Start again.':
      'Muda wa kuweka upya umeisha. Anza tena.',
  'Enter the full verification code.': 'Weka msimbo kamili wa uthibitisho.',
  'your phone or email': 'simu au barua pepe yako',
  'Verify Account': 'Thibitisha akaunti',
  'Enter the verification code sent to':
      'Weka msimbo wa uthibitisho uliotumwa kwa',
  'Verification': 'Uthibitisho',
  'Enter Security Code': 'Weka msimbo wa usalama',
  'We sent a 6-digit verification code to {destination}.':
      'Tumetuma msimbo wa tarakimu 6 kwenda {destination}.',
  'Resend or change destination': 'Tuma tena au badili mahali pa kutuma',
  'Resend code will be enabled after the resend endpoint is added.': 'Kutuma tena msimbo kutawezeshwa baada ya sehemu ya kutuma tena kuongezwa.',
  'Resend email': 'Tuma tena barua pepe',
  'Resend code': 'Tuma tena msimbo',
  'Sending code': 'Inatuma msimbo',
  'A new verification code has been sent.':
      'Msimbo mpya wa uthibitisho umetumwa.',
  'Verifying': 'Inathibitisha',
  'Verify': 'Thibitisha',
  'Verify & Proceed': 'Thibitisha na endelea',
  'Code expires in {time}': 'Msimbo utaisha baada ya {time}',
  'Change email address': 'Badili barua pepe',
  'Change phone number': 'Badili namba ya simu',
  'Verification code expired. Request a new code.':
      'Msimbo wa uthibitisho umeisha. Omba msimbo mpya.',
  'Vikoplus Mutual Trust Guarantee': 'Dhamana ya uaminifu ya Vikoplus',
  'Your account credentials remain end-to-end protected.':
      'Taarifa zako za kuingia hubaki salama mwanzo hadi mwisho.',
  'Reset Password': 'Weka upya nenosiri',
  'Password does not meet requirements.': 'Nenosiri halijakidhi masharti.',
  'Passwords do not match.': 'Nenosiri hayafanani.',
  'Create New Password': 'Tengeneza nenosiri jipya',
  'Your new password must be unique and satisfy the security requirements below.': 'Nenosiri jipya liwe la kipekee na litimize masharti ya usalama hapa chini.',
  'New Password': 'Nenosiri jipya',
  'Password': 'Nenosiri',
  'Show password': 'Onyesha nenosiri',
  'Hide password': 'Ficha nenosiri',
  'Confirm New Password': 'Thibitisha nenosiri jipya',
  'Confirm password': 'Thibitisha nenosiri',
  'At least 8 characters': 'Angalau herufi 8',
  'Uppercase and lowercase letters': 'Herufi kubwa na ndogo',
  'At least one number': 'Angalau namba moja',
  'A special symbol': 'Alama maalum',
  'Passwords match': 'Nenosiri yanafanana',
  'Updating': 'Inasasisha',
  'Update Password': 'Sasisha nenosiri',
  'Login': 'Ingia',
  'Password Changed!': 'Nenosiri limebadilishwa!',
  'Your password has been reset successfully. You can now sign in with your new credentials.':
      'Nenosiri lako limewekwa upya. Sasa unaweza kuingia kwa taarifa mpya.',
  'Security Audit': 'Ukaguzi wa usalama',
  'Password reset verified and active sessions ended.': 
  'Uwekaji upya wa nenosiri umethibitishwa na vipindi vilivyokuwa hai vimefungwa.',
  'Back to Sign In': 'Rudi kuingia',
  'Configure Reminders': 'Weka vikumbusho',
  'Reminder Package': 'Kifurushi cha vikumbusho',
  'Schedule': 'Ratiba',
  'Message Preview': 'Muonekano wa ujumbe',
  'Save and Continue': 'Hifadhi na endelea',
  'Configure Later': 'Weka baadaye',
  'Saving': 'Inahifadhi',
  'Create a group before buying reminders.':
      'Unda kikundi kabla ya kununua vikumbusho.',
  'Checkout link copied to clipboard.': 'Kiungo cha malipo kimenakiliwa.',
  'Checkout link copied.': 'Kiungo cha malipo kimenakiliwa.',
  'Refresh to load the current reminder settings before saving.':
      'Onyesha upya ili kupakia mipangilio ya sasa kabla ya kuhifadhi.',
  'Create a group before setting reminders.':
      'Unda kikundi kabla ya kuweka vikumbusho.',
  'Enable Automatic Reminders': 'Washa vikumbusho vya moja kwa moja',
  'Send automated payment alerts to members. Admin pays messaging costs separately from member contributions.': 
  'Tuma taarifa za malipo kwa wanachama moja kwa moja. Msimamizi hulipia gharama za ujumbe tofauti na michango ya wanachama.',
  '3 days before due date': 'Siku 3 kabla ya tarehe ya malipo',
  'On due date': 'Siku ya malipo',
  '3 days overdue': 'Siku 3 baada ya kuchelewa',
  'Create a group before choosing reminder packages.':
      'Unda kikundi kabla ya kuchagua vifurushi vya vikumbusho.',
  'Could not load reminder packages.': 'Vifurushi vya vikumbusho havijapakiwa.',
  'Reminder package prices are not available yet.':
      'Bei za vifurushi vya vikumbusho bado hazipo.',
  'per message': 'kwa ujumbe',
  'Message credits': 'Idadi ya ujumbe',
  '100 messages': 'Ujumbe 100',
  '500 messages': 'Ujumbe 500',
  '1,000 messages': 'Ujumbe 1,000',
  '5,000 messages': 'Ujumbe 5,000',
  'Creating checkout': 'Inatengeneza kiungo cha malipo',
  'Create checkout link': 'Tengeneza kiungo cha malipo',
  'Checkout link ready': 'Kiungo cha malipo kiko tayari',
  'Copy checkout link': 'Nakili kiungo cha malipo',
  'SMS and WhatsApp reminders': 'Vikumbusho vya SMS na WhatsApp',
  'Reminder messages': 'Ujumbe wa vikumbusho',
  'Estimated checkout total': 'Makadirio ya jumla ya malipo',
  'Hi {member_name}, this is a friendly reminder that your payment of {amount} for your group is due soon.':
  'Habari {member_name}, hiki ni kikumbusho kuwa malipo yako ya {amount} ya kikundi yanakaribia.',
  'Group profile': 'Wasifu wa kikundi',
  'Update the group icon and visible identity':
      'Sasisha alama na utambulisho wa kikundi',
  'No active group': 'Hakuna kikundi kilichochaguliwa',
  'Add or replace the group icon shown in the app bar and group list.': 
  'Ongeza au badili alama ya kikundi inayoonekana juu ya app na kwenye orodha ya vikundi.',
  'Group icon updated.': 'Alama ya kikundi imesasishwa.',
  'Uploading': 'Inapakia',
  'Add Group Icon': 'Ongeza alama ya kikundi',
  'Replace Group Icon': 'Badili alama ya kikundi',
  'Only group admins can update the group icon.':
      'Wasimamizi wa kikundi pekee wanaweza kusasisha alama ya kikundi.',
  'Complete all required fields.': 'Jaza sehemu zote muhimu.',
  'Password must be at least 8 characters.':
      'Nenosiri lazima liwe na angalau herufi 8.',
  'Accept the terms before creating an account.':
      'Kubali vigezo kabla ya kutengeneza akaunti.',
  'John Doe': 'Jina kamili',
  'Creating account': 'Inatengeneza akaunti',
  'Create account': 'Tengeneza akaunti',
  'Already have an account? ': 'Tayari una akaunti? ',
  'Log in': 'Ingia',
  'Enter group name': 'Weka jina la kikundi',
  'Enter a valid group name.': 'Weka jina sahihi la kikundi.',
  'API returned an empty response.':
      'Seva haijarudisha taarifa. Tafadhali jaribu tena.',
  'Image upload failed.': 'Upakiaji wa picha umeshindikana.',
  'Image upload response was invalid.': 'Jibu la upakiaji wa picha si sahihi.',
  'Group image access denied.': 'Huna ruhusa ya kupakia picha ya kikundi hiki.',
  'Group access denied.': 'Huna ruhusa ya kufikia kikundi hiki.',
  'Role is not allowed for this action.':
      'Jukumu lako haliruhusiwi kufanya kitendo hiki.',
  'Enter your full name.': 'Weka jina lako kamili.',
  'Push token is required.': 'Tokeni ya taarifa inahitajika.',
  'Enter a positive penalty amount.': 'Weka kiasi cha faini kilicho sahihi.',
  'Invitation was not found or has expired.':
      'Mwaliko haujapatikana au muda wake umeisha.',
  'Select a reminder schedule.': 'Chagua ratiba ya vikumbusho.',
  'Member number range exhausted.':
      'Namba za wanachama zimeisha kwenye mpangilio huu.',
  'Member not found.': 'Mwanachama hajapatikana.',
  'Receipt not found.': 'Risiti haijapatikana.',
  'Reminder package was not found.': 'Kifurushi cha vikumbusho hakijapatikana.',
  'Select active members from this group.':
      'Chagua wanachama hai kutoka kikundi hiki.',
  'Briq SMS reminder delivery failed.':
      'Utumaji wa vikumbusho vya SMS kupitia Briq umeshindikana.',
  'You cannot guarantee your own loan.':
      'Huwezi kudhamini mkopo wako mwenyewe.',
  'Notification not found.': 'Taarifa haijapatikana.',
  'Contribution frequency is not supported.':
      'Mzunguko huu wa michango haujasaidiwa.',
  'This invitation has already been accepted.':
      'Mwaliko huu tayari umekubaliwa.',
  'This invitation belongs to another user.':
      'Mwaliko huu ni wa mtumiaji mwingine.',
  'name must be longer than or equal to 2 characters':
      'Jina la kikundi lazima liwe na angalau herufi 2.',
  'name must be shorter than or equal to 100 characters':
      'Jina la kikundi lisizidi herufi 100.',
  'name should not be empty': 'Jina la kikundi linahitajika.',
  'name must be a string': 'Jina la kikundi lazima liwe maandishi.',
  'type must be shorter than or equal to 50 characters':
      'Aina ya kikundi isizidi herufi 50.',
  'description must be shorter than or equal to 500 characters':
      'Maelezo yasizidi herufi 500.',
  'location must be shorter than or equal to 100 characters':
      'Eneo lisizidi herufi 100.',
  'currency must be longer than or equal to 3 characters':
      'Sarafu lazima iwe na herufi 3.',
  'currency must be shorter than or equal to 3 characters':
      'Sarafu lazima iwe na herufi 3.',
  'establishedAt must be a valid ISO 8601 date string':
      'Tarehe ya kuanzishwa si sahihi.',
  'historicalDataStartsAt must be a valid ISO 8601 date string':
      'Tarehe ya kuanza kumbukumbu za zamani si sahihi.',
  'Description': 'Maelezo',
  '(Optional)': '(Si lazima)',
  'What is this group about?': 'Kikundi hiki kinahusu nini?',
  'Location': 'Eneo',
  'City or Region': 'Jiji au mkoa',
  'Group Established Date': 'Tarehe kikundi kilipoanzishwa',
  'When did this group start?': 'Kikundi kilianza lini?',
  'Historical Records Start': 'Mwanzo wa kumbukumbu za zamani',
  'Earliest data to import': 'Tarehe ya kwanza ya data ya kuingiza',
  'Existing groups can keep their real start date and import previous contribution records after setup.': 
  'kundi vilivyokuwepo vinaweza kuweka tarehe yao halisi ya kuanza na kuingiza kumbukumbu za michango ya zamani baada ya usanidi.',
  'Change Group Logo': 'Badili nembo ya kikundi',
  'Upload Group Logo': 'Pakia nembo ya kikundi',
  'Group Type': 'Aina ya kikundi',
  'Select group type': 'Chagua aina ya kikundi',
  'Family': 'Familia',
  'Savings': 'Akiba',
  'Welfare': 'Ustawi',
  'Investment': 'Uwekezaji',
  'TZS - Tanzanian Shilling (Locked)': 'TZS - Shilingi ya Tanzania (imefungwa)',
  'Creating group': 'Inaunda kikundi',
  'Financial Year': 'Mwaka wa fedha',
  'Configure Cycle': 'Weka mzunguko',
  "Set the start and end of your group's financial year. This determines reporting and contribution cycles.": 
  'Weka mwanzo na mwisho wa mwaka wa fedha wa kikundi. Hii huamua ripoti na mizunguko ya michango.',
  'Create a group before setting its financial year.':
      'Unda kikundi kabla ya kuweka mwaka wake wa fedha.',
  'Recommended current year': 'Mwaka wa sasa unaopendekezwa',
  'Current Financial Year': 'Mwaka wa fedha wa sasa',
  'Start Date': 'Tarehe ya kuanza',
  'End Date (Calculated)': 'Tarehe ya mwisho (imekokotolewa)',
  'Current Period Preview': 'Muonekano wa kipindi cha sasa',
  'Calculated as one full year from your selected start date.':
      'Inakokotolewa kama mwaka mmoja kamili kuanzia tarehe uliyochagua.',
  'Automatic Rollover': 'Hamisho la mwaka kiotomatiki',
  'Start the next year automatically after the end date.':
      'Anzisha mwaka unaofuata kiotomatiki baada ya tarehe ya mwisho.',
  "The financial year defines the 12-month period for your group's accounting, contribution tracking, and annual reports.": 
      'Mwaka wa fedha hufafanua kipindi cha miezi 12 kwa hesabu, ufuatiliaji wa michango, na ripoti za mwaka za kikundi.',
  'Enter a valid invitation code.': 'Weka msimbo sahihi wa mwaliko.',
  'Enter Group Code': 'Weka msimbo wa kikundi',
  'Use the invitation code shared by your group administrator.':
      'Tumia msimbo wa mwaliko uliotumwa na msimamizi wa kikundi.',
  'Invitation code': 'Msimbo wa mwaliko',
  'Verify group details': 'Thibitisha taarifa za kikundi',
  'Join an existing group': 'Jiunge na kikundi kilichopo',
  'Invitation required': 'Mwaliko unahitajika',
  '{count} Members': 'Wanachama {count}',
  '{count} Member': 'Mwanachama {count}',
  'After joining, review your fees and contributions. Pay your group leader and submit payment details for treasurer approval.': 
      'Baada ya kujiunga, angalia ada na michango yako. Lipa kwa kiongozi wa kikundi kisha wasilisha taarifa za malipo ili mweka hazina aidhinishe.',
  'You will join as {role}.': 'Utajiunga kama {role}.',
  'Enter Code to Join': 'Weka msimbo kujiunga',
  'Checking code': 'Inakagua msimbo',
  'Verify Group': 'Thibitisha kikundi',
  'Invitation code required': 'Msimbo wa mwaliko unahitajika',
  'Enter an invitation code to verify a group.':
      'Weka msimbo wa mwaliko ili kuthibitisha kikundi.',
  'Enter Code': 'Weka msimbo',
  'Could not verify group.': 'Imeshindikana kuthibitisha kikundi.',
  'Try Another Code': 'Jaribu msimbo mwingine',
  'Role: {role}': 'Wajibu: {role}',
  'Your invitation is valid. Join this group to access your member workspace.': 
      'Mwaliko wako ni sahihi. Jiunge na kikundi hiki ili kufikia eneo lako la mwanachama.',
  'Welcome to {groupName}!': 'Karibu {groupName}!',
  'You are the group administrator. Activate yearly group access before inviting members and managing contributions.': 
      'Wewe ni msimamizi wa kikundi. Washa huduma ya mwaka ya kikundi kabla ya kualika wanachama na kusimamia michango.',
  'Next Steps': 'Hatua zinazofuata',
  'Activate yearly group access': 'Washa huduma ya mwaka ya kikundi',
  'TZS 10,000 per group per year.': 'TZS 10,000 kwa kikundi kwa mwaka.',
  'Invite members and assign roles': 'Alika wanachama na gawa majukumu',
  'Chairperson/admin controls member permissions.':
      'Mwenyekiti/msimamizi husimamia ruhusa za wanachama.',
  'Admin or secretary can add old contribution data.':
      'Msimamizi au katibu anaweza kuongeza data ya michango ya zamani.',
  'Choose plan': 'Chagua mpango',
  'Contribution Register': 'Rejesta ya michango',
  'Record payment': 'Rekodi malipo',
  'Record Payment': 'Rekodi malipo',
  'Select a group before recording payment.':
      'Chagua kikundi kabla ya kurekodi malipo.',
  'Select a member before recording payment.':
      'Chagua mwanachama kabla ya kurekodi malipo.',
  'Could not load this member. Please select again.':
      'Imeshindikana kupakia mwanachama huyu. Tafadhali chagua tena.',
  'Contribution Purpose': 'Sababu ya mchango',
  'Could not load this member contributions.':
      'Imeshindikana kupakia michango ya mwanachama huyu.',
  'This member has no outstanding contributions.':
      'Mwanachama huyu hana michango inayodaiwa.',
  'Select at least one payable contribution.':
      'Chagua angalau mchango mmoja unaoweza kulipwa.',
  'Amount from selected purpose': 'Kiasi kutokana na michango iliyochaguliwa',
  'Payment Date': 'Tarehe ya malipo',
  'Transaction Reference': 'Kumbukumbu ya muamala',
  'Payment was not recorded. Confirm your staff role and try again.':
      'Malipo hayakurekodiwa. Thibitisha jukumu lako kisha jaribu tena.',
  'Some selected contributions are not payable.':
      'Baadhi ya michango iliyochaguliwa haiwezi kulipwa sasa.',
  'No group selected': 'Hakuna kikundi kilichochaguliwa',
  'Select a group to view contribution payments.':
      'Chagua kikundi ili kuona malipo ya michango.',
  'Could not load contribution payments.':
      'Imeshindikana kupakia malipo ya michango.',
  'Total approved contributions': 'Jumla ya michango iliyoidhinishwa',
  'Approved': 'Imeidhinishwa',
  'No member payments are waiting for review.':
      'Hakuna malipo ya wanachama yanayosubiri ukaguzi.',
  'Recent Payments': 'Malipo ya karibuni',
  'No contribution payments have been recorded yet.':
      'Hakuna malipo ya michango yaliyorekodiwa bado.',
  'Reject': 'Kataa',
  'Approve': 'Idhinisha',
  'Payment was not approved. Please try again.':
      'Malipo hayakuweza kuidhinishwa. Jaribu tena.',
  'Payment was not rejected. Please try again.':
      'Malipo hayakuweza kukataliwa. Jaribu tena.',
  'Review payments': 'Kagua malipo',
  'Approve or reject submitted contributions':
      'Idhinisha au kataa michango iliyowasilishwa',
  'Submit this contribution for secretary or treasurer verification.':
      'Wasilisha mchango huu ukaguliwe na katibu au mweka hazina.',
  'More': 'Zaidi',
  'Switch, create or join a group': 'Badili, unda au jiunge na kikundi',
  'Group rules, member roles, historical records and audit logs': 
  'Kanuni za kikundi, majukumu ya wanachama, kumbukumbu za zamani na kumbukumbu za ukaguzi',
  'Billing overview': 'Muhtasari wa malipo ya huduma',
  'Group access subscription and payments':
      'Usajili wa huduma ya kikundi na malipo',
  'SMS reminders and delivery history':
      'Vikumbusho vya SMS na historia ya utumaji',
  'Applications, guarantees and repayments': 'Maombi, dhamana na marejesho',
  'My loans': 'Mikopo yangu',
  'Import previous group records': 'Ingiza kumbukumbu za zamani za kikundi',
  'Photo and account details': 'Picha na taarifa za akaunti',
  'Personal alert preferences': 'Mapendeleo ya taarifa binafsi',
  'English or Swahili': 'Kiingereza au Kiswahili',
  'English': 'Kiingereza',
  'Kiswahili': 'Kiswahili',
  'You can switch the app language here.':
      'Unaweza kubadili lugha ya programu hapa.',
  'Complete Profile': 'Kamilisha wasifu',
  'Add your photo and account details':
      'Ongeza picha yako na taarifa za akaunti',
  'Member number': 'Namba ya mwanachama',
  'Phone number': 'Namba ya simu',
  'Email address': 'Barua pepe',
  'Not provided': 'Haijawekwa',
  'Secretary Portal': 'Dashibodi ya katibu',
  'Manage member records and group documentation.':
      'Simamia kumbukumbu za wanachama na nyaraka za kikundi.',
  'Secretary duties': 'Majukumu ya katibu',
  'Member directory': 'Orodha ya wanachama',
  'View member contacts, roles and status':
      'Angalia mawasiliano, majukumu na hali za wanachama',
  'Prepare notices for members with dues':
      'Andaa taarifa kwa wanachama wenye madeni',
  'Personal actions': 'Hatua binafsi',
  'My payments': 'Malipo yangu',
  'Pay your own group contributions': 'Lipa michango yako ya kikundi',
  'Group records snapshot': 'Muhtasari wa kumbukumbu za kikundi',
  'Records': 'Kumbukumbu',
  'Group expenses': 'Matumizi ya kikundi',
  'Record expense': 'Rekodi matumizi',
  'Record group spending for approval':
      'Rekodi matumizi ya kikundi kwa ajili ya idhini',
  'Record and approve group spending':
      'Rekodi na idhinisha matumizi ya kikundi',
  'Record and review group spending': 'Rekodi na hakiki matumizi ya kikundi',
  'Group money position': 'Hali ya fedha za kikundi',
  'Approved expenses': 'Matumizi yaliyoidhinishwa',
  'Pending expenses': 'Matumizi yanayosubiri',
  'Loans out': 'Mikopo iliyotolewa',
  'Available for expenses': 'Kiasi kinachopatikana kwa matumizi',
  'Available: {amount}': 'Kinachopatikana: {amount}',
  'Group has no available cash for expenses.':
      'Kikundi hakina fedha zinazopatikana kwa matumizi.',
  'Expense amount exceeds available group cash.':
      'Kiasi cha matumizi kimezidi fedha za kikundi zinazopatikana.',
  'Expense history': 'Historia ya matumizi',
  'Expense category': 'Aina ya matumizi',
  'Example: Condolences, bank charges': 'Mfano: Rambirambi, ada za benki',
  'Disbursement amount': 'Kiasi cha kutoa',
  'Beneficiary or recipient': 'Mnufaika au mpokeaji',
  'Beneficiary': 'Mnufaika',
  'Payment rail': 'Njia ya malipo',
  'Reference': 'Kumbukumbu',
  'Submit expense': 'Wasilisha matumizi',
  'No group expenses recorded yet.':
      'Hakuna matumizi ya kikundi yaliyorekodiwa bado.',
  'Open a group before recording expenses.':
      'Fungua kikundi kabla ya kurekodi matumizi.',
  'Could not load expenses.': 'Matumizi hayajapakiwa.',
  'Enter a valid expense amount.': 'Weka kiasi sahihi cha matumizi.',
  'Enter the expense category.': 'Weka aina ya matumizi.',
  'Enter the expense purpose.': 'Weka sababu ya matumizi.',
  'Expense was not found.': 'Matumizi hayajapatikana.',
  'Expense has already been reviewed.': 'Matumizi haya tayari yamehakikiwa.',
  'Contribution plan for historical type is not configured.':
      'Mpango wa mchango wa aina hii haujawekwa kwenye kikundi.',
  'Expense pending approval': 'Matumizi yanasubiri idhini',
  'Expense approved': 'Matumizi yameidhinishwa',
  'Expense rejected': 'Matumizi yamekataliwa',
  'Cash balance': 'Salio la fedha',
  'Net group cash': 'Salio halisi la kikundi',
  'Expenses': 'Matumizi',
  'Condolences & Benevolent': 'Rambirambi na msaada',
  'Medical Emergency': 'Dharura ya matibabu',
  'Meeting & Hall Venue': 'Mkutano na ukumbi',
  'Admin & Bank Charges': 'Ada za uendeshaji na benki',
  'M-Pesa B2C Payout': 'Malipo ya M-Pesa B2C',
  'SUBMITTED': 'Imewasilishwa',
  'APPROVED': 'Imeidhinishwa',
  'REJECTED': 'Imekataliwa',
  'Logout': 'Toka',
  'Logging out': 'Inatoka',
  'End your session on this device': 'Maliza kipindi chako kwenye kifaa hiki',
  'Single Payment': 'Malipo moja',
  'Contribution type': 'Aina ya mchango',
  'Amount Paid': 'Kiasi kilicholipwa',
  'Receipt, book page, or old ledger note':
      'Risiti, ukurasa wa daftari, au rejea ya kumbukumbu za zamani',
  'Bulk Import': 'Ingiza kwa wingi',
  'Paste CSV rows prepared from the old ledger. Each row should include member number, contribution type, amount, method, paid date, and reference.':
  'Bandika mistari ya CSV kutoka kumbukumbu za zamani. Kila mstari uwe na namba ya mwanachama, aina ya mchango, kiasi, njia, tarehe ya malipo, na rejea.',
  'Share CSV template': 'Shiriki kiolezo cha CSV',
  'CSV rows': 'Mistari ya CSV',
  'Method': 'Njia',
  'Paid date': 'Tarehe ya malipo',
  'Import rules': 'Masharti ya kuingiza kumbukumbu',
  'Only group admin and secretary can import.':
      'Msimamizi wa kikundi na katibu pekee wanaweza kuingiza kumbukumbu.',
  'Imported records are approved manual payments.':
      'Kumbukumbu zilizoingizwa huhesabiwa kama malipo yaliyothibitishwa.',
  'Payment dates must be inside group history.':
      'Tarehe za malipo lazima ziwe ndani ya historia ya kikundi.',
  'Receipts and audit logs are created.':
      'Risiti na kumbukumbu za ukaguzi hutengenezwa.',
  'Save Historical Payment': 'Hifadhi malipo ya zamani',
  'Import Records': 'Ingiza kumbukumbu',
  'Skip Historical Records': 'Ruka kumbukumbu za zamani',
  'CSV must include a header and at least one row.':
      'CSV lazima iwe na vichwa vya safu na angalau mstari mmoja.',
  'CSV is missing a required column.': 'CSV haina safu muhimu inayohitajika.',
  'CSV has an empty required field.': 'CSV ina sehemu muhimu iliyo tupu.',
  'CSV has no importable rows.': 'CSV haina mistari inayoweza kuingizwa.',
  'CSV row member was not found.':
      'Mwanachama kwenye mstari wa CSV hajapatikana.',
  'CSV row has an invalid amount.': 'Mstari wa CSV una kiasi kisicho sahihi.',
  'CSV row has an invalid paid date.':
      'Mstari wa CSV una tarehe ya malipo isiyo sahihi.',
  'CSV row has an invalid contribution type.':
      'Mstari wa CSV una aina ya mchango isiyo sahihi.',
  'CSV preview': 'Muhtasari wa CSV',
  'records ready': 'kumbukumbu tayari',
  'Total amount': 'Jumla ya kiasi',
  'Records by type': 'Kumbukumbu kwa aina',
  'Historical payment dates cannot be before the group historical start date.': 
  'Tarehe za malipo ya zamani haziwezi kuwa kabla ya tarehe ya kuanza historia ya kikundi.',
  'RECURRING': 'Mchango wa kawaida',
  'JOINING_FEE': 'Ada ya kujiunga',
  'MEMBERSHIP_FEE': 'Ada ya uanachama',
};
