# Share Place To Visit

## Overview

Add the ability to share a Place To Visit with others via the system share sheet. When sharing, the app generates a formatted text message with the place details and opens the iOS share extension.

## User Flow

1. User opens a Place To Visit detail screen
2. User taps the "Share" button (in toolbar menu or actions section)
3. App generates formatted share text
4. System share sheet opens with options (Messages, WhatsApp, Email, Copy, etc.)

## Share Text Format

```
Hey! I want to visit this place with you:
<Name>
<Address or Google Maps link>
<URL (if available)>
```

**Examples:**

With address:
```
Hey! I want to visit this place with you:
Eiffel Tower
Champ de Mars, 5 Av. Anatole France, 75007 Paris
https://www.toureiffel.paris
```

With Google Maps link (no separate URL):
```
Hey! I want to visit this place with you:
Best Pizza Place
https://maps.google.com/maps?q=...
```

With Google Maps link and URL:
```
Hey! I want to visit this place with you:
Amazing Restaurant
https://maps.google.com/maps?q=...
https://restaurant-website.com
```

---

## Implementation Plan

### Step 1: Add Share Button to Toolbar Menu

**Modify:** `JourneyWallet/Place/PlaceDetailView.swift`

Add a "Share" button to the existing toolbar menu:

```swift
// In toolbar Menu, after "Move to Journey" button:
Button {
    sharePlace()
} label: {
    Label(L("common.share"), systemImage: "square.and.arrow.up")
}
```

### Step 2: Add Share State and Sheet

**Modify:** `JourneyWallet/Place/PlaceDetailView.swift`

Add state variable and sheet:

```swift
// Add state variable
@State private var showShareSheet: Bool = false
@State private var shareText: String = ""

// Add sheet modifier (after existing sheets)
.sheet(isPresented: $showShareSheet) {
    ShareSheet(items: [shareText])
}
```

### Step 3: Implement Share Text Generation

**Modify:** `JourneyWallet/Place/PlaceDetailView.swift`

Add method to generate share text:

```swift
private func sharePlace() {
    var components: [String] = []

    // Header
    components.append(L("place.share.header"))

    // Name
    components.append(viewModel.place.name)

    // Address (could be text or Google Maps link)
    if let address = viewModel.place.address, !address.isEmpty {
        components.append(address)
    }

    // URL (if different from address)
    if let url = viewModel.place.url, !url.isEmpty {
        // Only add URL if it's different from address
        if let address = viewModel.place.address, address != url {
            components.append(url)
        } else if viewModel.place.address == nil || viewModel.place.address?.isEmpty == true {
            components.append(url)
        }
    }

    shareText = components.joined(separator: "\n")
    showShareSheet = true
}
```

### Step 4: Add Share Button to Actions Section (Optional)

For more visibility, also add a share button in the actions section:

```swift
// In actionsSection, add share button:
Button(action: {
    sharePlace()
}) {
    HStack {
        Image(systemName: "square.and.arrow.up")
        Text(L("common.share"))
    }
    .frame(maxWidth: .infinity)
    .padding()
    .background(Color.orange)
    .foregroundColor(.white)
    .cornerRadius(12)
}
```

### Step 5: Add Localization Strings

**Modify all `Localizable.strings` files:**

```
/* Share Place */
"place.share.header" = "Hey! I want to visit this place with you:";
```

| Language | Translation |
|----------|-------------|
| English | "Hey! I want to visit this place with you:" |
| German | "Hey! Ich möchte diesen Ort mit dir besuchen:" |
| Russian | "Привет! Хочу посетить это место с тобой:" |
| Turkish | "Hey! Bu yeri seninle ziyaret etmek istiyorum:" |
| Kazakh | "Сәлем! Бұл жерге сенімен барғым келеді:" |
| Ukrainian | "Привіт! Хочу відвідати це місце з тобою:" |

---

## File Summary

| Action | File |
|--------|------|
| Modify | `JourneyWallet/Place/PlaceDetailView.swift` |
| Modify | `JourneyWallet/en.lproj/Localizable.strings` |
| Modify | `JourneyWallet/de.lproj/Localizable.strings` |
| Modify | `JourneyWallet/ru.lproj/Localizable.strings` |
| Modify | `JourneyWallet/tr.lproj/Localizable.strings` |
| Modify | `JourneyWallet/kk.lproj/Localizable.strings` |
| Modify | `JourneyWallet/uk.lproj/Localizable.strings` |

---

## Existing Components Used

- **ShareSheet** (`JourneyWallet/Shared/ShareSheet.swift`) - Already exists, wraps `UIActivityViewController`
- **L()** function for localization

---

## Edge Cases

| Scenario | Behavior |
|----------|----------|
| No address, no URL | Share only name with header |
| Address is Google Maps link, URL exists | Include both (Maps link + URL) |
| Address is Google Maps link, no URL | Include only Maps link |
| Address is text, URL exists | Include both |
| Address is text, no URL | Include only address |
| Address equals URL | Include only once (avoid duplication) |

---

## Future Enhancements

1. **Share as image** - Generate a nice card image to share
2. **Share to specific apps** - Quick share buttons for WhatsApp, Telegram
3. **Include journey info** - Option to include "From my trip to Paris" context
4. **QR Code** - Generate QR code for the place URL
