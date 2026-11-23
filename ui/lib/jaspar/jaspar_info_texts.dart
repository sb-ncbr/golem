// Texts shown behind the "i" buttons.

// TODO: these are working drafts describing what the UI does today.
// It can/must be changed + my explanation might not be the best.

const String infoDialogTitle = 'JASPAR Import';
const String infoDialogText =
    'Import a logo from JASPAR, adjust it if needed and turn it into an '
    'IUPAC motif.';

const String infoImportTitle = 'Import logo';
const String infoImportText =
    'Download a logo from the JASPAR database by its matrix ID (for example '
    'MA0001.1) and press Download. Details of the downloaded logo appear '
    'below the field.\n\n'
    'You can also skip the download and edit the PFM table in the Sequence '
    'Logo section directly.';

const String infoSequenceLogoTitle = 'Sequence Logo';
const String infoSequenceLogoText =
    'The table is the position frequency matrix (PFM): how often each '
    'nucleotide (A, C, G, T) was observed at every position of the binding '
    'site. The logo above it shows the same data - the taller a letter, the '
    'more conserved that nucleotide is at the position.\n\n'
    'Keyboard\n'
    '• Click a cell, then use ↑ / ↓ to change its value. Hold the key to '
    'repeat, hold Shift to change by 10.\n'
    '• Use ← / → to jump to the neighbouring position.';

const String infoConsensusTitle = 'Adjust consensus generation method';
const String infoConsensusText =
    'The matrix is converted to a motif written in IUPAC codes using slighty '
    'modified Cavener (1987) rules. The preview updates as you change the settings.\n\n'
    '• Single-base threshold: a position becomes a single base when that '
    'base reaches this share and is at least twice as frequent as the '
    'runner-up.\n'
    '• 2/3-base threshold: otherwise the two or three most frequent bases '
    'are merged into one IUPAC code when together they exceed this share.\n'
    '• Everything else becomes N.\n\n'
    'Optionally, positions with low information content are forced to N, and '
    'leading/trailing N positions can be trimmed.';

const String infoSingleBaseTitle = 'Single-base threshold';
const String infoSingleBaseText =
    'A position gets a single-base code when that base reaches this share '
    'and is at least twice as frequent as the runner-up.';

const String infoMultiBaseTitle = '2/3-base threshold';
const String infoMultiBaseText =
    'Two or three bases are merged into one IUPAC code (e.g. R, Y, B) when '
    'together they exceed this share.';

const String infoLowInfoTitle = 'Low-information positions';
const String infoLowInfoText =
    'Positions that carry little information are replaced by N.';

const String infoIcThresholdTitle = 'Information content threshold';
const String infoIcThresholdText =
    'Positions with an information content below this value (0-2 bits) '
    'become N.';

const String infoTrimTitle = 'Trim flanks';
const String infoTrimText =
    'Cuts leading and trailing N positions off the final logo. When it is '
    'off, the final logo keeps them. The preview always shows them, dimmed '
    'when this option is on.';

const String infoConsensusOutputTitle = 'Consensus output';
const String infoConsensusOutputText =
    'Each position is coloured by its IUPAC code. With "Trim flanks" on, '
    'leading and trailing N positions are dimmed and left out of the final '
    'logo.';

const String infoFinalLogoTitle = 'Final logo';
const String infoFinalLogoText =
    'The IUPAC motif that will be added to your motif definition. Leading and '
    'trailing N positions are only left out when "Trim flanks" is on.';
