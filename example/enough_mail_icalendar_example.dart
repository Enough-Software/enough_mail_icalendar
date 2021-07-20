import 'package:enough_icalendar/enough_icalendar.dart';
import 'package:enough_mail/enough_mail.dart';
import 'package:enough_mail_icalendar/enough_mail_icalendar.dart';

void main() {
  final invite = createInvite();
  buildCalendarInviteMessage(invite);
  buildAcceptReplyMessage(invite);
}

void buildCalendarInviteMessage(VCalendar invite) {
  final builder = VMessageBuilder.prepareFromCalendar(invite);
  final mimeMessage = builder.buildMimeMessage();
  print('==========================');
  print('invite message:');
  print('==========================');
  print(mimeMessage);
  // you can now send the MimeMessage as any other message, e.g. with `MailClient.sendMessage(mimeMessage)`
}

void buildAcceptReplyMessage(VCalendar invite) {
  final me = MailAddress('Donna Strickland', 'b@example.com');
  final acceptMessageBuilder = VMessageBuilder.prepareCalendarReply(
    invite,
    ParticipantStatus.accepted,
    me,
  );
  final mimeMessage = acceptMessageBuilder.buildMimeMessage();
  print('\n==========================');
  print('reply message:');
  print('==========================');
  print(mimeMessage);
}

Future sendCalendarReply(
  VCalendar calendar,
  ParticipantStatus participantStatus,
  MimeMessage originatingMessage,
  MailClient mailClient,
) {
  // generate reply email message, send it, set message flags:
  return mailClient.sendCalendarReply(calendar, participantStatus,
      originatingMessage: originatingMessage);
}

ParticipantStatus? getParticipantStatus(MimeMessage message) {
  // the ParticipantStatus can be detected from the message flags when
  //the flag was added successfully before
  final participantStatus = message.calendarParticipantStatus;
  if (participantStatus != null) {
    print(
        'detected ${participantStatus.name} through flag ${participantStatus.flag}');
  } else {
    print('no participant status flag detected in ${message.flags}');
  }
  return participantStatus;
}

VCalendar createInvite() {
  final me = MailAddress('Andrea Ghez', 'a@example.com');
  final invitees = [
    MailAddress('Andrea Ghez', 'a@example.com'),
    MailAddress('Donna Strickland', 'b@example.com'),
    MailAddress('Maria Goeppert Mayer', 'c@example.com'),
    MailAddress('Marie Curie, née Sklodowska', 'c@example.com'),
  ];
  final invite = VCalendar.createEvent(
    start: DateTime(2021, 08, 01, 11, 00),
    duration: IsoDuration(hours: 1),
    organizer: me.organizer,
    attendees: invitees.map((address) => address.attendee).toList(),
    location: 'Stockholm',
    summary: 'Physics Winners',
    description: 'Let\'s discuss what to research next.',
  );
  return invite;
}
