import '../../../l10n/generated/app_localizations.dart';
import '../../tour/domain/start_point.dart';

String startPointName(AppLocalizations l10n, String id) =>
    id == StartPointIds.naturfreundehaus
    ? l10n.startPointNfhName
    : l10n.startPointBfName;

String startPointDetail(AppLocalizations l10n, String id) =>
    id == StartPointIds.naturfreundehaus
    ? l10n.startPointNfhDetail
    : l10n.startPointBfDetail;
