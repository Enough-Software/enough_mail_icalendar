# enough_mail_icalendar
iCalendar support for email / mime. Compatible with the iCalendar Message-Based Interoperability Protocol (iMIP) [RFC 6047](https://datatracker.ietf.org/doc/html/rfc6047).

## Installation
Add this dependency your pubspec.yaml file:

```
dependencies:
  enough_mail_icalendar: ^0.1.0
  enough_mail: latest
  enough_icalendar: latest
```
The latest version or `enough_mail_icalendar` is [![enough_mail_icalendar version](https://img.shields.io/pub/v/enough_mail_icalendar.svg)](https://pub.dartlang.org/packages/enough_mail_icalendar).



## API Documentation
Check out the full API documentation at https://pub.dev/documentation/enough_mail_icalendar/latest/

## Usage

Use `enough_mail_icalendar` to generate and send MIME email messages for iCalendar requests. 

### Import

```dart
import 'package:enough_icalendar/enough_icalendar.dart';
import 'package:enough_mail/enough_mail.dart';
import 'package:enough_mail_icalendar/enough_mail_icalendar.dart';
```
### Generate a MimeMessage for a VCalendar
With `VMessageBuilder.prepareFromCalendar(...)` create a MIME message builder for a given `VCalendar` object.

```dart
void buildCalendarInviteMessage(VCalendar invite) {
  final builder = VMessageBuilder.prepareFromCalendar(invite);
  final mimeMessage = builder.buildMimeMessage();
  print(mimeMessage);
  // you can now send the MimeMessage as any other message, e.g. with `MailClient.sendMessage(mimeMessage)`
}
```
### Generate a Reply MimeMessage for a Received VCalendar
Use `VMessageBuilder.prepareCalendarReply(...)` to create a reply MIME message for a received VCalendar.
In the following example the invite is accepted.
```dart
void buildAcceptReplyMessage(VCalendar invite) {
  final me = MailAddress('Donna Strickland', 'b@example.com');
  final acceptMessageBuilder = VMessageBuilder.prepareCalendarReply(
    invite,
    ParticipantStatus.accepted,
    me,
  );
  final mimeMessage = acceptMessageBuilder.buildMimeMessage();
  print(mimeMessage);
}
```
### Send a Reply directly for a Received VCalendar
Send a reply directly with the `MailClient.sendCalendarReply()` instance method. This will generate the 
mime message, send it and update the originating message's flags, when the message is specified and when the 
mail service supports arbitrary message flags.
```dart
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
```

### Check if a Reply has been Send for a MimeMessage
Use the `calendarParticipantStatus` getter on a `MimeMessage` instance to check for participation status flags that have been set earlier.
```dart
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
```

## Features and bugs

`enough_mail_icalendar` should be fully compliant with the iCalendar Message-Based Interoperability Protocol (iMIP) [RFC 6047](https://datatracker.ietf.org/doc/html/rfc6047).


Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/Enough-Software/enough_mail_icalendar/issues

## Null-Safety
`enough_mail_icalendar` is null-safe.

## License
`enough_mail_icalendar` is licensed under the commercial friendly [Mozilla Public License 2.0](LICENSE)

