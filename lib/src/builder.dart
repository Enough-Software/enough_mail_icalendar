import 'package:enough_icalendar/enough_icalendar.dart';
import 'package:enough_mail/enough_mail.dart';
import 'extensions.dart';

class VMessageBuilder {
  VMessageBuilder._();

  /// Prepares a message builder with a request for the specified [calendar].
  static MessageBuilder prepareFromCalendar(
    VCalendar calendar, {
    List<MailAddress> toRecipients = const [],
    List<MailAddress> ccRecipients = const [],
    List<MailAddress> bccRecipients = const [],
    String? plaintTextPart,
    MailAddress? from,
    String filename = 'invite.ics',
    String? subject,
  }) {
    final organizer = calendar.organizer;
    if (from == null && (organizer == null || organizer.email == null)) {
      throw StateError(
          'Either the [from] parameter must be set or the calendar requires a child with an [organizer] set.');
    }

    final builder = MessageBuilder.prepareMultipartMixedMessage();
    builder.subject = subject ?? calendar.summary ?? 'Invite';
    final fromSender = from ?? calendar.organizerMailAddress!;
    builder.from = [fromSender];
    if (toRecipients.isEmpty && ccRecipients.isEmpty && bccRecipients.isEmpty) {
      final attendees = calendar.attendees;
      if (attendees == null || attendees.isEmpty) {
        throw StateError(
            'Warning: neither recipients specified nor attendees found in calendar');
      }
      builder.to = calendar.attendeeMailAddresses;
    } else {
      builder.to = toRecipients;
      builder.cc = ccRecipients;
      builder.bcc = bccRecipients;
    }
    final text = plaintTextPart ??
        calendar.description ??
        calendar.summary ??
        'This message contains an calendar invite';
    builder.addTextPlain(text);
    final calendarPart = builder.addText(
      calendar.toString(),
      mediaType: MediaSubtype.textCalendar.mediaType,
      disposition: ContentDispositionHeader.from(
        ContentDisposition.attachment,
        filename: filename,
      ),
    );
    if (calendar.method != null) {
      final contentType = calendarPart.contentType!;
      contentType.parameters['method'] = calendar.method!.name;
    }
    return builder;
  }

  static MessageBuilder prepareCalendarReply(
    VCalendar calendar,
    ParticipantStatus participantStatus,
    MailAddress from, {
    String? comment,
    String productId = 'enough_mail with enough_icalendar',
    String icsFilename = 'reply.ics',
  }) {
    final organizer = calendar.organizer;
    if (organizer == null || organizer.email == null) {
      throw StateError(
          'VCALENDAR has no organizer or the organizer has no email: $organizer');
    }
    final reply = calendar.replyWithParticipantStatus(
      participantStatus,
      attendeeEmail: from.email,
      comment: comment,
      productId: productId,
    );
    final subject =
        MessageBuilder.createReplySubject(calendar.summary ?? 'Invite');
    final messageBuilder = prepareFromCalendar(
      reply,
      from: from,
      toRecipients: [organizer.mailAddress!],
      filename: icsFilename,
      plaintTextPart: comment ??
          '"${calendar.summary}" is ${participantStatus.name} by $from.',
      subject: subject,
    );
    return messageBuilder;
  }
}
