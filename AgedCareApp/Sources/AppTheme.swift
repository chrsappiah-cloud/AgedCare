import SwiftUI

enum AppTheme {
  static let emeraldRed = Color(red: 0.76, green: 0.12, blue: 0.20)
  static let emeraldRedDark = Color(red: 0.55, green: 0.06, blue: 0.12)
  static let emeraldRedLight = Color(red: 0.95, green: 0.60, blue: 0.65)
  static let emeraldGreen = Color(red: 0.20, green: 0.67, blue: 0.33)
  static let emeraldGreenDark = Color(red: 0.11, green: 0.47, blue: 0.21)
  static let emeraldGreenLight = Color(red: 0.72, green: 0.90, blue: 0.78)
  static let diamondWhite = Color(red: 0.96, green: 0.97, blue: 0.98)
  static let diamondSilver = Color(red: 0.82, green: 0.84, blue: 0.87)
  static let diamondSparkle = Color(red: 1.0, green: 1.0, blue: 1.0)
  static let darkChocolate = Color(red: 0.27, green: 0.16, blue: 0.09)
  static let darkChocolateLight = Color(red: 0.45, green: 0.30, blue: 0.20)
  static let darkChocolateBg = Color(red: 0.18, green: 0.10, blue: 0.05)

  static let primary = emeraldGreen
  static let primaryDark = emeraldGreenDark
  static let accent = emeraldRed
  static let accentLight = emeraldRedLight
  static let background = diamondWhite
  static let surface = diamondSparkle
  static let textPrimary = darkChocolate
  static let textSecondary = darkChocolateLight
  static let textOnPrimary = diamondSparkle
  static let success = emeraldGreen
  static let danger = emeraldRed
  static let warning = Color(red: 0.85, green: 0.55, blue: 0.10)

  static let gradientEmeraldGreen = LinearGradient(
    colors: [emeraldGreen, emeraldGreenDark],
    startPoint: .leading, endPoint: .trailing
  )
  static let gradientEmeraldRed = LinearGradient(
    colors: [emeraldRed, emeraldRedDark],
    startPoint: .leading, endPoint: .trailing
  )
  static let gradientChocolate = LinearGradient(
    colors: [darkChocolate, darkChocolateLight],
    startPoint: .leading, endPoint: .trailing
  )
  static let gradientDiamond = LinearGradient(
    colors: [diamondWhite, diamondSilver],
    startPoint: .top, endPoint: .bottom
  )
}

extension View {
  func cardStyle() -> some View {
    self
      .background(AppTheme.surface)
      .cornerRadius(16)
      .shadow(color: AppTheme.darkChocolate.opacity(0.08), radius: 8, x: 0, y: 4)
  }

  func primaryButtonStyle() -> some View {
    self
      .font(.headline)
      .padding()
      .frame(maxWidth: .infinity)
      .background(AppTheme.gradientEmeraldGreen)
      .foregroundColor(AppTheme.textOnPrimary)
      .cornerRadius(14)
      .shadow(color: AppTheme.emeraldGreen.opacity(0.3), radius: 6, x: 0, y: 3)
  }

  func dangerButtonStyle() -> some View {
    self
      .font(.headline)
      .padding()
      .frame(maxWidth: .infinity)
      .background(AppTheme.gradientEmeraldRed)
      .foregroundColor(AppTheme.textOnPrimary)
      .cornerRadius(14)
      .shadow(color: AppTheme.emeraldRed.opacity(0.3), radius: 6, x: 0, y: 3)
  }

  func accentChip(_ isSelected: Bool) -> some View {
    self
      .padding(.horizontal, 14)
      .padding(.vertical, 6)
      .background(isSelected ? AppTheme.emeraldGreen : AppTheme.diamondSilver.opacity(0.4))
      .foregroundColor(isSelected ? AppTheme.textOnPrimary : AppTheme.textSecondary)
      .cornerRadius(20)
      .overlay(
        RoundedRectangle(cornerRadius: 20)
          .stroke(isSelected ? AppTheme.emeraldGreen : Color.clear, lineWidth: 1)
      )
  }

  func sectionHeaderStyle() -> some View {
    self
      .font(.caption.uppercaseSmallCaps().bold())
      .foregroundColor(AppTheme.darkChocolateLight)
      .padding(.horizontal)
      .padding(.top, 8)
  }
}
