// Les échelles de couleur, développées en OKLCH par jetons.mjs : pas = 1000 × (1 − clarté), de 50 en 50.
// fabriqué depuis tokens.json par sophos/outils/jetons.mjs ; ne pas modifier à la main (patron 1.1.0).
import SwiftUI

enum DesignPrimitive {
    /// oklch(0.9491 0.0000 none) · Encre et Graphite : texte en clair, fond et surfaces en sombre.
    static let ink50: UInt32 = 0xEEEEEE
    /// oklch(0.9006 0.0000 none) · Encre et Graphite : texte en clair, fond et surfaces en sombre.
    static let ink100: UInt32 = 0xDEDEDE
    /// oklch(0.8015 0.0000 none) · Encre et Graphite : texte en clair, fond et surfaces en sombre.
    static let ink200: UInt32 = 0xBEBEBE
    /// oklch(0.6993 0.0000 none) · Encre et Graphite : texte en clair, fond et surfaces en sombre.
    static let ink300: UInt32 = 0x9E9E9E
    /// oklch(0.5999 0.0000 none) · Encre et Graphite : texte en clair, fond et surfaces en sombre.
    static let ink400: UInt32 = 0x808080
    /// oklch(0.4997 0.0000 none) · Encre et Graphite : texte en clair, fond et surfaces en sombre.
    static let ink500: UInt32 = 0x636363
    /// oklch(0.3979 0.0000 none) · Encre et Graphite : texte en clair, fond et surfaces en sombre.
    static let ink600: UInt32 = 0x474747
    /// oklch(0.3012 0.0000 none) · Encre et Graphite : texte en clair, fond et surfaces en sombre.
    static let ink700: UInt32 = 0x2E2E2E
    /// oklch(0.2520 0.0000 none) · Encre et Graphite : texte en clair, fond et surfaces en sombre.
    static let ink750: UInt32 = 0x222222
    /// oklch(0.1913 0.0000 none) · Encre et Graphite : texte en clair, fond et surfaces en sombre.
    static let ink800: UInt32 = 0x141414
    /// oklch(0.0969 0.0000 none) · Encre et Graphite : texte en clair, fond et surfaces en sombre.
    static let ink900: UInt32 = 0x030303
    /// oklch(0.9851 0.0000 none) · Papier et Brume : fond et surfaces en clair, texte en sombre.
    static let paper0: UInt32 = 0xFAFAFA
    /// oklch(0.9491 0.0000 none) · Papier et Brume : fond et surfaces en clair, texte en sombre.
    static let paper50: UInt32 = 0xEEEEEE
    /// oklch(0.9195 0.0045 134.9) · Papier et Brume : fond et surfaces en clair, texte en sombre.
    static let paper100: UInt32 = 0xE3E5E2
    /// oklch(0.8015 0.0000 none) · Papier et Brume : fond et surfaces en clair, texte en sombre.
    static let paper200: UInt32 = 0xBEBEBE
    /// oklch(0.6993 0.0000 none) · Papier et Brume : fond et surfaces en clair, texte en sombre.
    static let paper300: UInt32 = 0x9E9E9E
    /// oklch(0.5999 0.0000 none) · Papier et Brume : fond et surfaces en clair, texte en sombre.
    static let paper400: UInt32 = 0x808080
    /// oklch(0.4997 0.0000 none) · Papier et Brume : fond et surfaces en clair, texte en sombre.
    static let paper500: UInt32 = 0x636363
    /// oklch(0.4017 0.0000 none) · Papier et Brume : fond et surfaces en clair, texte en sombre.
    static let paper600: UInt32 = 0x484848
    /// oklch(0.3012 0.0000 none) · Papier et Brume : fond et surfaces en clair, texte en sombre.
    static let paper700: UInt32 = 0x2E2E2E
    /// oklch(0.2002 0.0000 none) · Papier et Brume : fond et surfaces en clair, texte en sombre.
    static let paper800: UInt32 = 0x161616
    /// oklch(0.0969 0.0000 none) · Papier et Brume : fond et surfaces en clair, texte en sombre.
    static let paper900: UInt32 = 0x030303
    /// oklch(0.9509 0.0245 26.9) · Rouge : l'erreur et la suppression ; jamais une décoration.
    static let red50: UInt32 = 0xFFE9E6
    /// oklch(0.9007 0.0516 27.0) · Rouge : l'erreur et la suppression ; jamais une décoration.
    static let red100: UInt32 = 0xFFD2CC
    /// oklch(0.7992 0.1149 26.4) · Rouge : l'erreur et la suppression ; jamais une décoration.
    static let red200: UInt32 = 0xFFA096
    /// oklch(0.6996 0.1705 27.0) · Rouge : l'erreur et la suppression ; jamais une décoration.
    static let red300: UInt32 = 0xF66D62
    /// oklch(0.6008 0.1706 26.9) · Rouge : l'erreur et la suppression ; jamais une décoration.
    static let red400: UInt32 = 0xD34D45
    /// oklch(0.5496 0.1706 26.9) · Rouge : l'erreur et la suppression ; jamais une décoration.
    static let red450: UInt32 = 0xC13C36
    /// oklch(0.5001 0.1712 26.9) · Rouge : l'erreur et la suppression ; jamais une décoration.
    static let red500: UInt32 = 0xB02A27
    /// oklch(0.4005 0.1632 26.9) · Rouge : l'erreur et la suppression ; jamais une décoration.
    static let red600: UInt32 = 0x8B000B
    /// oklch(0.3009 0.1226 26.8) · Rouge : l'erreur et la suppression ; jamais une décoration.
    static let red700: UInt32 = 0x5D0005
    /// oklch(0.1994 0.0814 27.5) · Rouge : l'erreur et la suppression ; jamais une décoration.
    static let red800: UInt32 = 0x320001
    /// oklch(0.0999 0.0410 29.2) · Rouge : l'erreur et la suppression ; jamais une décoration.
    static let red900: UInt32 = 0x0D0000
    /// oklch(0.9497 0.0838 149.9) · Vert : la réussite confirmée ; jamais une décoration.
    static let green50: UInt32 = 0xC7FFD1
    /// oklch(0.9005 0.1208 149.6) · Vert : la réussite confirmée ; jamais une décoration.
    static let green100: UInt32 = 0xA3F5B3
    /// oklch(0.8007 0.1213 150.0) · Vert : la réussite confirmée ; jamais une décoration.
    static let green200: UInt32 = 0x82D494
    /// oklch(0.6992 0.1204 149.7) · Vert : la réussite confirmée ; jamais une décoration.
    static let green300: UInt32 = 0x63B375
    /// oklch(0.6001 0.1207 149.9) · Vert : la réussite confirmée ; jamais une décoration.
    static let green400: UInt32 = 0x439458
    /// oklch(0.5512 0.1207 149.8) · Vert : la réussite confirmée ; jamais une décoration.
    static let green450: UInt32 = 0x33854A
    /// oklch(0.5012 0.1207 149.9) · Vert : la réussite confirmée ; jamais une décoration.
    static let green500: UInt32 = 0x21763C
    /// oklch(0.3992 0.1104 149.8) · Vert : la réussite confirmée ; jamais une décoration.
    static let green600: UInt32 = 0x005724
    /// oklch(0.3011 0.0834 149.8) · Vert : la réussite confirmée ; jamais une décoration.
    static let green700: UInt32 = 0x003915
    /// oklch(0.2015 0.0564 149.3) · Vert : la réussite confirmée ; jamais une décoration.
    static let green800: UInt32 = 0x001D07
    /// oklch(0.1005 0.0274 150.5) · Vert : la réussite confirmée ; jamais une décoration.
    static let green900: UInt32 = 0x000501
    /// oklch(0.9503 0.0363 70.0) · Ambre : l'avertissement ; jamais une décoration.
    static let amber50: UInt32 = 0xFFEBD5
    /// oklch(0.9001 0.0753 69.9) · Ambre : l'avertissement ; jamais une décoration.
    static let amber100: UInt32 = 0xFFD6A8
    /// oklch(0.8008 0.1195 70.2) · Ambre : l'avertissement ; jamais une décoration.
    static let amber200: UInt32 = 0xEFB063
    /// oklch(0.6991 0.1186 69.9) · Ambre : l'avertissement ; jamais une décoration.
    static let amber300: UInt32 = 0xCD9043
    /// oklch(0.6006 0.1192 70.1) · Ambre : l'avertissement ; jamais une décoration.
    static let amber400: UInt32 = 0xAD721E
    /// oklch(0.5502 0.1192 70.0) · Ambre : l'avertissement ; jamais une décoration.
    static let amber450: UInt32 = 0x9D6300
    /// oklch(0.4999 0.1085 69.6) · Ambre : l'avertissement ; jamais une décoration.
    static let amber500: UInt32 = 0x8A5600
    /// oklch(0.4006 0.0868 70.0) · Ambre : l'avertissement ; jamais une décoration.
    static let amber600: UInt32 = 0x653E00
    /// oklch(0.3000 0.0649 70.3) · Ambre : l'avertissement ; jamais une décoration.
    static let amber700: UInt32 = 0x422700
    /// oklch(0.1999 0.0431 70.9) · Ambre : l'avertissement ; jamais une décoration.
    static let amber800: UInt32 = 0x221200
    /// oklch(0.0977 0.0227 60.9) · Ambre : l'avertissement ; jamais une décoration.
    static let amber900: UInt32 = 0x070200
    /// oklch(0.9506 0.0240 253.9) · Bleu : l'information neutre ; jamais l'accent de la marque.
    static let blue50: UInt32 = 0xE4F0FF
    /// oklch(0.8996 0.0493 255.9) · Bleu : l'information neutre ; jamais l'accent de la marque.
    static let blue100: UInt32 = 0xC9E0FF
    /// oklch(0.8004 0.1022 255.1) · Bleu : l'information neutre ; jamais l'accent de la marque.
    static let blue200: UInt32 = 0x91C1FF
    /// oklch(0.7002 0.1291 254.7) · Bleu : l'information neutre ; jamais l'accent de la marque.
    static let blue300: UInt32 = 0x64A1ED
    /// oklch(0.6009 0.1297 254.8) · Bleu : l'information neutre ; jamais l'accent de la marque.
    static let blue400: UInt32 = 0x4682CC
    /// oklch(0.5489 0.1298 255.1) · Bleu : l'information neutre ; jamais l'accent de la marque.
    static let blue450: UInt32 = 0x3772BB
    /// oklch(0.4991 0.1301 255.3) · Bleu : l'information neutre ; jamais l'accent de la marque.
    static let blue500: UInt32 = 0x2863AB
    /// oklch(0.3998 0.1296 255.1) · Bleu : l'information neutre ; jamais l'accent de la marque.
    static let blue600: UInt32 = 0x03468B
    /// oklch(0.2990 0.1002 255.5) · Bleu : l'information neutre ; jamais l'accent de la marque.
    static let blue700: UInt32 = 0x002C5E
    /// oklch(0.1995 0.0666 255.4) · Bleu : l'information neutre ; jamais l'accent de la marque.
    static let blue800: UInt32 = 0x001533
    /// oklch(0.0988 0.0330 255.4) · Bleu : l'information neutre ; jamais l'accent de la marque.
    static let blue900: UInt32 = 0x00030D
    /// oklch(0.9499 0.0629 199.8) (brand) · L'accent de la palette choisie : clair au pas 500, sombre au pas 200.
    static func accent50(_ variant: DesignPalette) -> UInt32 {
        switch variant {
        case .brand: return 0xBDFCFF
        case .graphite: return 0xEEEEEE
        case .teal: return 0xBDFCFF
        case .mint: return 0xBFFFE4
        case .lavender: return 0xF4E9FF
        case .sky: return 0xE0F1FF
        case .polar: return 0xDEF2FF
        }
    }
    /// oklch(0.9008 0.0748 199.0) (brand) · L'accent de la palette choisie : clair au pas 500, sombre au pas 200.
    static func accent100(_ variant: DesignPalette) -> UInt32 {
        switch variant {
        case .brand: return 0xA2EEF1
        case .graphite: return 0xDEDEDE
        case .teal: return 0xA2EEF1
        case .mint: return 0xADEFD4
        case .lavender: return 0xE9D4FF
        case .sky: return 0xBFE3FF
        case .polar: return 0xBCE4FF
        }
    }
    /// oklch(0.7673 0.0706 193.5) (brand) · L'accent de la palette choisie : clair au pas 500, sombre au pas 200.
    static func accent200(_ variant: DesignPalette) -> UInt32 {
        switch variant {
        case .brand: return 0x7CC2C0
        case .graphite: return 0xD6D6D6
        case .teal: return 0x9AD0C2
        case .mint: return 0x9ED5C5
        case .lavender: return 0xD0A2F7
        case .sky: return 0x89CFF3
        case .polar: return 0x90D2F5
        }
    }
    /// oklch(0.7007 0.0749 200.0) (brand) · L'accent de la palette choisie : clair au pas 500, sombre au pas 200.
    static func accent300(_ variant: DesignPalette) -> UInt32 {
        switch variant {
        case .brand: return 0x62ADB1
        case .graphite: return 0x9E9E9E
        case .teal: return 0x62ADB1
        case .mint: return 0x6EAE95
        case .lavender: return 0xB686E0
        case .sky: return 0x53A7E1
        case .polar: return 0x55A8D9
        }
    }
    /// oklch(0.6009 0.0743 200.0) (brand) · L'accent de la palette choisie : clair au pas 500, sombre au pas 200.
    static func accent400(_ variant: DesignPalette) -> UInt32 {
        switch variant {
        case .brand: return 0x438E92
        case .graphite: return 0x808080
        case .teal: return 0x438E92
        case .mint: return 0x4F8F77
        case .lavender: return 0x9767BF
        case .sky: return 0x3088C0
        case .polar: return 0x3489B9
        }
    }
    /// oklch(0.4969 0.0744 199.9) (brand) · L'accent de la palette choisie : clair au pas 500, sombre au pas 200.
    static func accent500(_ variant: DesignPalette) -> UInt32 {
        switch variant {
        case .brand: return 0x1F6F73
        case .graphite: return 0x474747
        case .teal: return 0x1F6F73
        case .mint: return 0x2F7059
        case .lavender: return 0x78499E
        case .sky: return 0x006BA1
        case .polar: return 0x076C9A
        }
    }
    /// oklch(0.3988 0.0678 200.5) (brand) · L'accent de la palette choisie : clair au pas 500, sombre au pas 200.
    static func accent600(_ variant: DesignPalette) -> UInt32 {
        switch variant {
        case .brand: return 0x005256
        case .graphite: return 0x484848
        case .teal: return 0x005256
        case .mint: return 0x0C553F
        case .lavender: return 0x5C2C7F
        case .sky: return 0x004C75
        case .polar: return 0x004D71
        }
    }
    /// oklch(0.2992 0.0509 200.9) (brand) · L'accent de la palette choisie : clair au pas 500, sombre au pas 200.
    static func accent700(_ variant: DesignPalette) -> UInt32 {
        switch variant {
        case .brand: return 0x003538
        case .graphite: return 0x2E2E2E
        case .teal: return 0x003538
        case .mint: return 0x003727
        case .lavender: return 0x410C61
        case .sky: return 0x00314D
        case .polar: return 0x00324A
        }
    }
    /// oklch(0.2016 0.0343 198.1) (brand) · L'accent de la palette choisie : clair au pas 500, sombre au pas 200.
    static func accent800(_ variant: DesignPalette) -> UInt32 {
        switch variant {
        case .brand: return 0x001B1C
        case .graphite: return 0x161616
        case .teal: return 0x001B1C
        case .mint: return 0x001C12
        case .lavender: return 0x230038
        case .sky: return 0x001829
        case .polar: return 0x001827
        }
    }
    /// oklch(0.0976 0.0168 208.0) (brand) · L'accent de la palette choisie : clair au pas 500, sombre au pas 200.
    static func accent900(_ variant: DesignPalette) -> UInt32 {
        switch variant {
        case .brand: return 0x000405
        case .graphite: return 0x030303
        case .teal: return 0x000405
        case .mint: return 0x000503
        case .lavender: return 0x070010
        case .sky: return 0x000409
        case .polar: return 0x000408
        }
    }
    /// oklch(0.9491 0.0000 none) (brand) · Les quatre nuances qui montrent une palette dans le sélecteur, du plus foncé au plus clair.
    static func palettePreview50(_ variant: DesignPalette) -> UInt32 {
        switch variant {
        case .brand: return 0xEEEEEE
        case .graphite: return 0xEEEEEE
        case .teal: return 0xE1F1FF
        case .mint: return 0xC6FDE9
        case .lavender: return 0xF4E9FF
        case .sky: return 0xE0F1FF
        case .polar: return 0xDCF3FF
        }
    }
    /// oklch(0.9851 0.0000 none) (brand) · Les quatre nuances qui montrent une palette dans le sélecteur, du plus foncé au plus clair.
    static func palettePreview100(_ variant: DesignPalette) -> UInt32 {
        switch variant {
        case .brand: return 0xFAFAFA
        case .graphite: return 0xFAFAFA
        case .teal: return 0xECF4D6
        case .mint: return 0xDEF5E5
        case .lavender: return 0xF1EAFF
        case .sky: return 0xCDF5FD
        case .polar: return 0xF2F3F7
        }
    }
    /// oklch(0.8015 0.0000 none) (brand) · Les quatre nuances qui montrent une palette dans le sélecteur, du plus foncé au plus clair.
    static func palettePreview200(_ variant: DesignPalette) -> UInt32 {
        switch variant {
        case .brand: return 0xBEBEBE
        case .graphite: return 0xBEBEBE
        case .teal: return 0x96C3EC
        case .mint: return 0x96CBB8
        case .lavender: return 0xD5A7FC
        case .sky: return 0x7BC6FF
        case .polar: return 0x92C6E2
        }
    }
    /// oklch(0.9195 0.0045 134.9) (brand) · Les quatre nuances qui montrent une palette dans le sélecteur, du plus foncé au plus clair.
    static func palettePreview300(_ variant: DesignPalette) -> UInt32 {
        switch variant {
        case .brand: return 0xE3E5E2
        case .graphite: return 0xD6D6D6
        case .teal: return 0x9AD0C2
        case .mint: return 0xBCEAD5
        case .lavender: return 0xE5D4FF
        case .sky: return 0xA0E9FF
        case .polar: return 0x90D2F5
        }
    }
    /// oklch(0.5999 0.0000 none) (brand) · Les quatre nuances qui montrent une palette dans le sélecteur, du plus foncé au plus clair.
    static func palettePreview400(_ variant: DesignPalette) -> UInt32 {
        switch variant {
        case .brand: return 0x808080
        case .graphite: return 0x808080
        case .teal: return 0x5A85AB
        case .mint: return 0x598C7B
        case .lavender: return 0x9669BA
        case .sky: return 0x0088CE
        case .polar: return 0x5588A2
        }
    }
    /// oklch(0.4969 0.0744 199.9) (brand) · Les quatre nuances qui montrent une palette dans le sélecteur, du plus foncé au plus clair.
    static func palettePreview500(_ variant: DesignPalette) -> UInt32 {
        switch variant {
        case .brand: return 0x1F6F73
        case .graphite: return 0x707070
        case .teal: return 0x2D9596
        case .mint: return 0x9ED5C5
        case .lavender: return 0xDCBFFF
        case .sky: return 0x89CFF3
        case .polar: return 0x21A5EC
        }
    }
    /// oklch(0.4017 0.0000 none) (brand) · Les quatre nuances qui montrent une palette dans le sélecteur, du plus foncé au plus clair.
    static func palettePreview600(_ variant: DesignPalette) -> UInt32 {
        switch variant {
        case .brand: return 0x484848
        case .graphite: return 0x484848
        case .teal: return 0x214B6E
        case .mint: return 0x1E5243
        case .lavender: return 0x5B2F7B
        case .sky: return 0x004C76
        case .polar: return 0x194E65
        }
    }
    /// oklch(0.1913 0.0000 none) (brand) · Les quatre nuances qui montrent une palette dans le sélecteur, du plus foncé au plus clair.
    static func palettePreview700(_ variant: DesignPalette) -> UInt32 {
        switch variant {
        case .brand: return 0x141414
        case .graphite: return 0x333333
        case .teal: return 0x265073
        case .mint: return 0x8EC3B0
        case .lavender: return 0xD0A2F7
        case .sky: return 0x00A9FF
        case .polar: return 0x053F56
        }
    }
    /// oklch(0.2002 0.0000 none) (brand) · Les quatre nuances qui montrent une palette dans le sélecteur, du plus foncé au plus clair.
    static func palettePreview800(_ variant: DesignPalette) -> UInt32 {
        switch variant {
        case .brand: return 0x161616
        case .graphite: return 0x161616
        case .teal: return 0x00172C
        case .mint: return 0x001C13
        case .lavender: return 0x230038
        case .sky: return 0x00182A
        case .polar: return 0x001925
        }
    }
    /// oklch(0.0969 0.0000 none) (brand) · Les quatre nuances qui montrent une palette dans le sélecteur, du plus foncé au plus clair.
    static func palettePreview900(_ variant: DesignPalette) -> UInt32 {
        switch variant {
        case .brand: return 0x030303
        case .graphite: return 0x030303
        case .teal: return 0x00040A
        case .mint: return 0x000503
        case .lavender: return 0x07000F
        case .sky: return 0x000409
        case .polar: return 0x000408
        }
    }
    /// oklch(0.9499 0.0629 199.8) (brand) · La teinte du verre du bandeau, selon la palette choisie.
    static func glass50(_ variant: DesignPalette) -> UInt32 {
        switch variant {
        case .brand: return 0xBDFCFF
        case .graphite: return 0xEEEEEE
        case .teal: return 0xB2FFFF
        case .mint: return 0xC6FDE9
        case .lavender: return 0xF4E9FF
        case .sky: return 0xE0F1FF
        case .polar: return 0xDFF1FF
        }
    }
    /// oklch(0.9008 0.0748 199.0) (brand) · La teinte du verre du bandeau, selon la palette choisie.
    static func glass100(_ variant: DesignPalette) -> UInt32 {
        switch variant {
        case .brand: return 0xA2EEF1
        case .graphite: return 0xDEDEDE
        case .teal: return 0x90F1F2
        case .mint: return 0xB6ECD8
        case .lavender: return 0xEAD3FF
        case .sky: return 0xC0E3FF
        case .polar: return 0xBEE4FF
        }
    }
    /// oklch(0.8009 0.0747 200.1) (brand) · La teinte du verre du bandeau, selon la palette choisie.
    static func glass200(_ variant: DesignPalette) -> UInt32 {
        switch variant {
        case .brand: return 0x82CDD1
        case .graphite: return 0xBEBEBE
        case .teal: return 0x6FD0D1
        case .mint: return 0x96CBB8
        case .lavender: return 0xD5A7FC
        case .sky: return 0x7BC6FF
        case .polar: return 0x75C8FF
        }
    }
    /// oklch(0.7007 0.0749 200.0) (brand) · La teinte du verre du bandeau, selon la palette choisie.
    static func glass300(_ variant: DesignPalette) -> UInt32 {
        switch variant {
        case .brand: return 0x62ADB1
        case .graphite: return 0x9E9E9E
        case .teal: return 0x4DB0B1
        case .mint: return 0x77AB99
        case .lavender: return 0xB588DB
        case .sky: return 0x00A7FD
        case .polar: return 0x28A9F0
        }
    }
    /// oklch(0.6009 0.0743 200.0) (brand) · La teinte du verre du bandeau, selon la palette choisie.
    static func glass400(_ variant: DesignPalette) -> UInt32 {
        switch variant {
        case .brand: return 0x438E92
        case .graphite: return 0x808080
        case .teal: return 0x279192
        case .mint: return 0x598C7B
        case .lavender: return 0x9669BA
        case .sky: return 0x0088CE
        case .polar: return 0x0089C8
        }
    }
    /// oklch(0.4969 0.0744 199.9) (brand) · La teinte du verre du bandeau, selon la palette choisie.
    static func glass500(_ variant: DesignPalette) -> UInt32 {
        switch variant {
        case .brand: return 0x1F6F73
        case .graphite: return 0x707070
        case .teal: return 0x2D9596
        case .mint: return 0x8EC3B0
        case .lavender: return 0xD0A2F7
        case .sky: return 0x00A9FF
        case .polar: return 0x21A5EC
        }
    }
    /// oklch(0.3988 0.0678 200.5) (brand) · La teinte du verre du bandeau, selon la palette choisie.
    static func glass600(_ variant: DesignPalette) -> UInt32 {
        switch variant {
        case .brand: return 0x005256
        case .graphite: return 0x484848
        case .teal: return 0x005354
        case .mint: return 0x1E5243
        case .lavender: return 0x5B2F7B
        case .sky: return 0x004C76
        case .polar: return 0x004D73
        }
    }
    /// oklch(0.2992 0.0509 200.9) (brand) · La teinte du verre du bandeau, selon la palette choisie.
    static func glass700(_ variant: DesignPalette) -> UInt32 {
        switch variant {
        case .brand: return 0x003538
        case .graphite: return 0x2E2E2E
        case .teal: return 0x003636
        case .mint: return 0x003729
        case .lavender: return 0x40115D
        case .sky: return 0x00314E
        case .polar: return 0x00314C
        }
    }
    /// oklch(0.2016 0.0343 198.1) (brand) · La teinte du verre du bandeau, selon la palette choisie.
    static func glass800(_ variant: DesignPalette) -> UInt32 {
        switch variant {
        case .brand: return 0x001B1C
        case .graphite: return 0x161616
        case .teal: return 0x001B1B
        case .mint: return 0x001C13
        case .lavender: return 0x230038
        case .sky: return 0x00182A
        case .polar: return 0x001828
        }
    }
    /// oklch(0.0976 0.0168 208.0) (brand) · La teinte du verre du bandeau, selon la palette choisie.
    static func glass900(_ variant: DesignPalette) -> UInt32 {
        switch variant {
        case .brand: return 0x000405
        case .graphite: return 0x030303
        case .teal: return 0x000405
        case .mint: return 0x000503
        case .lavender: return 0x07000F
        case .sky: return 0x000409
        case .polar: return 0x000409
        }
    }
}
