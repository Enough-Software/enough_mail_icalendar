import 'package:collection/collection.dart' show IterableExtension;
import 'package:enough_icalendar/enough_icalendar.dart';
import 'package:enough_mail/enough_mail.dart';

import 'builder.dart';

const String _icalFlagHeader = '\$ical';

/// iCal extension methods for enough_mail [MailClient]
extension ExtensionMailClient on MailClient {
  /// Changes the [participantStatus] for the given[calendar], e.g. to accept or decline a meeting request, generates and sends the corresponding message.
  ///
  /// When you specify the [originatingMessage] a flag will tried be stored marking this message as replied with the given [particpantStatus]. Compare [ExtensionMimeMessage.calendarParticipationStaus] getter.
  /// Optionally specify a [comment], the [productId] that ends up in the generated [VCalendar] reply
  /// and the [icsFilename] that defaults to `reply.ics`.
  Future<void> sendCalendarReply(
    VCalendar calendar,
    ParticipantStatus participantStatus, {
    MimeMessage? originatingMessage,
    String? comment,
    String productId = 'enough_mail with enough_icalendar',
    String icsFilename = 'reply.ics',
  }) async {
    final messageBuilder = VMessageBuilder.prepareCalendarReply(
      calendar,
      participantStatus,
      account.fromAddress,
      comment: comment,
      productId: productId,
      icsFilename: icsFilename,
    );
    await sendMessage(messageBuilder.buildMimeMessage());
    if (originatingMessage != null) {
      // flag originating message as replied with the participant status:
      final flagName = '$_icalFlagHeader${participantStatus.name!}';
      if (!originatingMessage.hasFlag(flagName)) {
        final existingIcalFlags = originatingMessage.flags
                ?.where((flag) => flag.startsWith(_icalFlagHeader)) ??
            [];
        final sequence = MessageSequence.fromMessage(originatingMessage);
        try {
          await store(
            sequence,
            [flagName, MessageFlags.answered],
            action: StoreAction.add,
          );
          if (existingIcalFlags.isNotEmpty) {
            await store(
              sequence,
              existingIcalFlags.toList(),
              action: StoreAction.remove,
            );
          }
        } catch (e, s) {
          print('Unable to store flag $flagName: $e $s');
        }
      }
    }
  }

  /// Sends out the given [calendar] invite.
  ///
  /// Optionally specify an explanation text in [plainTextPart] and
  /// specify the [icsFilename].
  Future<void> sendCalendarInvite(
    VCalendar calendar, {
    String? plainTextPart,
    String icsFilename = 'invite.ics',
  }) async {
    final messageBuilder = VMessageBuilder.prepareFromCalendar(
      calendar,
      from: account.fromAddress,
      filename: icsFilename,
      plainTextPart: plainTextPart,
    );
    await sendMessage(messageBuilder.buildMimeMessage());
  }
}

/// iCal extension methods for enough_mail [MimeMessage]
extension ExtensionMimeMessage on MimeMessage {
  /// Retries the participant status from the flags of this message
  ParticipantStatus? get calendarParticipantStatus {
    final flag =
        flags?.firstWhereOrNull((flag) => flag.startsWith(_icalFlagHeader));
    if (flag != null) {
      try {
        return ParticipantStatusParameter.parse(
            flag.substring(_icalFlagHeader.length));
      } catch (e) {
        print('Warning: unknown iCal ParticipationStatus flag found: [$flag]');
      }
    }
    return null;
  }
}

extension ExtensionCalendar on VCalendar {
  /// Retrieves the attendee mailing addresses from the first component
  /// with a attendees getter.
  List<MailAddress>? get attendeeMailAddresses => attendees
      ?.where((attendee) => attendee.email != null)
      .map((attendee) => MailAddress(attendee.commonName, attendee.email!))
      .toList();

  /// Gets the organizer as a [MailAddress] from the first component with
  /// an organizer getter.
  MailAddress? get organizerMailAddress {
    final o = organizer;
    if (o == null || o.email == null) {
      return null;
    }
    return MailAddress(o.commonName, o.email!);
  }
}

extension ExtensionAttendeeProperty on UserProperty {
  /// Retrieves the mail address
  MailAddress? get mailAddress {
    final mail = email;
    if (mail == null) {
      return null;
    }
    return MailAddress(commonName, mail);
  }
}

extension ExtensionMailAddress on MailAddress {
  /// Converts this mail address to an iCalendar attendee property
  AttendeeProperty get attendee =>
      AttendeeProperty.create(attendeeEmail: email, commonName: personalName)!;

  /// Converts this mail address to an iCalendar organizer property
  OrganizerProperty get organizer =>
      OrganizerProperty.create(email: email, commonName: personalName)!;
}

extension ExtensionMimePart on MimePart {
  /// Decodes this mime message part's content as a [VCalendar], if possible.
  VCalendar? decodeContentVCalendar() {
    if (mediaType.sub != MediaSubtype.textCalendar) {
      return null;
    }
    final text = decodeContentText();
    if (text == null) {
      return null;
    }
    final component = VComponent.parse(text);
    return component as VCalendar?;
  }
}

extension ExtensionParticipantStatus on ParticipantStatus {
  /// Retrieves the IMAP flag name for this participant status
  String get flag => '$_icalFlagHeader$name';
}
