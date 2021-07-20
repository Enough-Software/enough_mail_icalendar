import 'package:enough_icalendar/enough_icalendar.dart';
import 'package:enough_mail/enough_mail.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:enough_mail_icalendar/enough_mail_icalendar.dart';

void main() {
  test('create invite message', () {
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
    final builder = VMessageBuilder.prepareFromCalendar(invite);
    final message = builder.buildMimeMessage();
    // print(message);
    expect(message.decodeSubject(), 'Physics Winners');
    expect(message.mediaType.sub, MediaSubtype.multipartMixed);
    expect(message.fromEmail, 'a@example.com');
    expect(message.to, isNotEmpty);
    expect(message.to?.length, 4);
    expect(message.to![3].personalName, 'Marie Curie, née Sklodowska');
    expect(message.parts, isNotEmpty);
    expect(message.parts?.length, 2);
    expect(message.parts![0].mediaType.sub, MediaSubtype.textPlain);
    expect(message.parts![1].mediaType.sub, MediaSubtype.textCalendar);
    final decodedInvite = message.parts![1].decodeContentVCalendar();
    // print(decodedInvite);
    expect(decodedInvite, isNotNull);
    expect(decodedInvite!.description, 'Let\'s discuss what to research next.');
    expect(decodedInvite.method, Method.request);
  });

  test('Create participation response message', () {
    final inviteText =
        '''BEGIN:VCALENDAR
PRODID:enough_icalendar
VERSION:2.0
METHOD:REQUEST
BEGIN:VEVENT
DTSTAMP:20210720T165936
UID:ct8Vh0bF5o28nLO2A2@example.com
DTSTART:20210801T110000
DURATION:PT1H0M0S
ORGANIZER;CN=Andrea Ghez:mailto:a@example.com
SUMMARY:Physics Winners
DESCRIPTION:Let's discuss what to research next.
LOCATION:Stockholm
ATTENDEE;CN=Andrea Ghez:mailto:a@example.com
ATTENDEE;CN=Donna Strickland:mailto:b@example.com
ATTENDEE;CN=Maria Goeppert Mayer:mailto:c@example.com
ATTENDEE;CN="Marie Curie, née Sklodowska":mailto:c@example.com
END:VEVENT
END:VCALENDAR''';
    final invite = VComponent.parse(inviteText) as VCalendar;
    final me = MailAddress('Donna Strickland', 'b@example.com');
    final acceptMessageBuilder = VMessageBuilder.prepareCalendarReply(
      invite,
      ParticipantStatus.accepted,
      me,
    );
    final message = acceptMessageBuilder.buildMimeMessage();
    //print(message);
    expect(message.decodeSubject(), 'Re: Physics Winners');
    expect(message.mediaType.sub, MediaSubtype.multipartMixed);
    expect(message.fromEmail, 'b@example.com');
    expect(message.to, isNotEmpty);
    expect(message.to?.length, 1);
    expect(message.to![0].personalName, 'Andrea Ghez');
    expect(message.parts, isNotEmpty);
    expect(message.parts?.length, 2);
    expect(message.parts![0].mediaType.sub, MediaSubtype.textPlain);
    expect(message.parts![1].mediaType.sub, MediaSubtype.textCalendar);
    final decodedReply = message.parts![1].decodeContentVCalendar();
    // print(decodedInvite);
    expect(decodedReply, isNotNull);
    expect(decodedReply!.attendees, isNotEmpty);
    expect(decodedReply.attendees?.first.participantStatus,
        ParticipantStatus.accepted);
    expect(decodedReply.uid, invite.uid);
    expect(decodedReply.method, Method.reply);
  });
}
