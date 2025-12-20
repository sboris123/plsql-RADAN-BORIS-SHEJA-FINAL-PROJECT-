# Dashboard Mockups - Detailed Visual Descriptions
## Automated Customer Order Validation System
  
**Purpose:** Guide for creating professional dashboard mockups  


---

## Dashboard Design Principles

### Color Scheme
- **Primary:** Navy Blue (#003366) - Headers, titles
- **Secondary:** Light Blue (#4A90E2) - Charts, accents
- **Success:** Green (#28A745) - Positive metrics, up arrows
- **Warning:** Orange (#FF9800) - Alerts, attention needed
- **Danger:** Red (#DC3545) - Critical alerts, down arrows
- **Background:** Light Gray (#F8F9FA) - Dashboard background
- **Cards:** White (#FFFFFF) - Widget backgrounds

### Typography
- **Headers:** Arial Bold, 24-28pt
- **KPI Values:** Arial Bold, 36-48pt
- **KPI Labels:** Arial Regular, 14pt
- **Chart Labels:** Arial Regular, 12pt
- **Body Text:** Arial Regular, 13pt

### Layout Grid
- 12-column grid system
- 20px padding around dashboard
- 15px gap between widgets
- Responsive breakpoints: Desktop (1920px), Tablet (1024px), Mobile (768px)

---

## Dashboard 1: Executive Summary Dashboard

### Layout (1920x1080px)

```
┌─────────────────────────────────────────────────────────────────┐
│ EXECUTIVE SUMMARY | ShopSmart Rwanda         [User] [Logout]   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐          │
│ │ REVENUE  │ │ ORDERS   │ │ GROWTH   │ │ CUSTOMERS│          │
│ │ 42.5M RWF│ │   487    │ │  +12.5%  │ │   198    │          │
│ │ ↑ +8.2%  │ │ ↑ +5.3%  │ │ M-o-M    │ │ Active   │          │
│ └──────────┘ └──────────┘ └──────────┘ └──────────┘          │
│                                                                 │
│ ┌─────────────────────────────────┐ ┌───────────────────────┐ │
│ │ MONTHLY REVENUE TREND           │ │ ORDER STATUS          │ │
│ │                                 │ │                       │ │
│ │   [Line Chart: 12 months]      │ │   [Donut Chart]      │ │
│ │   Shows upward trend            │ │   • Delivered: 65%   │ │
│ │   Peak in Nov 2024              │ │   • Processing: 20%  │ │
│ │                                 │ │   • Pending: 10%     │ │
│ └─────────────────────────────────┘ │   • Cancelled: 5%    │ │
│                                     └───────────────────────┘ │
│ ┌─────────────────────────────────┐ ┌───────────────────────┐ │
│ │ TOP 10 CUSTOMERS                │ │ CATEGORY PERFORMANCE  │ │
│ │                                 │ │                       │ │
│ │ 1. Alice Mukamana  2.4M RWF    │ │ [Horizontal Bar]     │ │
│ │ 2. John Uwimana    1.9M RWF    │ │ Electronics: 8.5M    │ │
│ │ 3. Sarah Habimana  1.7M RWF    │ │ Clothing: 6.2M       │ │
│ │ 4. David Niyonzima 1.5M RWF    │ │ Food: 5.8M          │ │
│ │ 5. Marie Uwase     1.3M RWF    │ │ Home: 4.9M          │ │
│ └─────────────────────────────────┘ └───────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

### Detailed Component Specifications

#### KPI Cards (Top Row)
**Dimensions:** 250px x 150px each  
**Layout:** 4 cards, equal spacing

**Card 1: Revenue**
- **Value:** "42.5M RWF" (48pt, Bold, Navy)
- **Change:** "↑ +8.2%" (18pt, Green with up arrow)
- **Label:** "This Month" (14pt, Gray)
- **Icon:** 💰 Money bag icon (top-right, 32px)
- **Background:** White with subtle shadow
- **Border:** 1px solid #E0E0E0

**Card 2: Orders**
- **Value:** "487" (48pt, Bold, Navy)
- **Change:** "↑ +5.3%" (18pt, Green)
- **Label:** "Orders This Month" (14pt, Gray)
- **Icon:** 📦 Package icon
- **Same styling as Card 1**

**Card 3: Growth**
- **Value:** "+12.5%" (48pt, Bold, Green)
- **Change:** "Month-over-Month" (14pt, Gray)
- **Label:** "Revenue Growth" (14pt, Gray)
- **Icon:** 📈 Trending up icon
- **Background gradient:** Light green to white

**Card 4: Customers**
- **Value:** "198" (48pt, Bold, Navy)
- **Label:** "Active Customers" (14pt, Gray)
- **Sub-label:** "8 new this week" (12pt, Gray)
- **Icon:** 👥 Users icon

#### Monthly Revenue Trend Chart
**Dimensions:** 600px x 350px  
**Type:** Line Chart

**Chart Specifications:**
- **X-Axis:** Jan 2024 to Dec 2024 (12 months)
- **Y-Axis:** Revenue in millions (0M to 50M)
- **Line Color:** Blue (#4A90E2), 3px width
- **Data Points:** Circles, 6px diameter
- **Grid:** Horizontal lines, light gray (#E0E0E0)
- **Background:** White
- **Title:** "Monthly Revenue Trend" (18pt, Bold)

**Sample Data Points:**
- Jan: 28M, Feb: 30M, Mar: 32M, Apr: 35M
- May: 38M, Jun: 36M, Jul: 39M, Aug: 41M
- Sep: 40M, Oct: 43M, Nov: 45M, Dec: 42.5M

**Annotations:**
- Peak marker on Nov: "Peak: 45M RWF"
- Trend line showing overall growth

#### Order Status Donut Chart
**Dimensions:** 300px x 350px  
**Type:** Donut Chart

**Chart Specifications:**
- **Center Value:** "487" (Total Orders)
- **Segments:**
  - Delivered: 65% (Green #28A745)
  - Processing: 20% (Orange #FF9800)
  - Pending: 10% (Blue #4A90E2)
  - Cancelled: 5% (Red #DC3545)
- **Legend:** Right side with values
- **Title:** "Order Status Distribution"

#### Top 10 Customers Table
**Dimensions:** 600px x 300px  
**Type:** Ranked List

**Table Structure:**
| Rank | Customer Name | Revenue | Orders | Last Order |
|------|---------------|---------|--------|------------|
| 1    | Alice Mukamana | 2.4M RWF | 45 | 2 days ago |
| 2    | John Uwimana | 1.9M RWF | 38 | 5 days ago |
| ... | ... | ... | ... | ... |

**Styling:**
- Alternating row colors (#FFFFFF and #F8F9FA)
- Top 3 rows highlighted with gold, silver, bronze left border
- Hover effect: Light blue background

#### Category Performance Bar Chart
**Dimensions:** 300px x 300px  
**Type:** Horizontal Bar Chart

**Categories & Values:**
- Electronics: 8.5M RWF (Bar color: #4A90E2)
- Clothing: 6.2M RWF (Bar color: #9C27B0)
- Food & Beverages: 5.8M RWF (Bar color: #FF9800)
- Home & Garden: 4.9M RWF (Bar color: #4CAF50)
- Sports: 4.2M RWF (Bar color: #F44336)

**Bar Specifications:**
- Height: 40px each
- Rounded corners: 4px
- Values displayed at end of bars
- Title: "Revenue by Category"

---

## Dashboard 2: Sales Performance Dashboard

### Layout

```
┌─────────────────────────────────────────────────────────────────┐
│ SALES PERFORMANCE | Today: Dec 4, 2024        [Refresh] [⚙]    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐          │
│ │ TODAY    │ │ AVG ORDER│ │ SUCCESS  │ │ TEAM     │          │
│ │ 850K RWF │ │  85K RWF │ │  96.2%   │ │ 8 Active │          │
│ │ 15 orders│ │ Target OK│ │ ↑ +2.1%  │ │ 25 Total │          │
│ └──────────┘ └──────────┘ └──────────┘ └──────────┘          │
│                                                                 │
│ ┌─────────────────────────────────┐ ┌───────────────────────┐ │
│ │ HOURLY SALES (Last 24h)        │ │ SALES BY USER         │ │
│ │                                 │ │                       │ │
│ │   [Area Chart]                 │ │ [Bar Chart]          │ │
│ │   Peak: 2-4 PM                 │ │ Marie: 12 orders     │ │
│ │   Low: 2-6 AM                  │ │ John: 10 orders      │ │
│ │                                 │ │ Peter: 8 orders      │ │
│ └─────────────────────────────────┘ └───────────────────────┘ │
│                                                                 │
│ ┌─────────────────────────────────┐ ┌───────────────────────┐ │
│ │ TOP PRODUCTS TODAY              │ │ RECENT LARGE ORDERS   │ │
│ │                                 │ │                       │ │
│ │ 1. Premium Electronics #23      │ │ Order #4567: 850K    │ │
│ │    Qty: 8 | Rev: 200K          │ │ Order #4589: 720K    │ │
│ │ 2. Deluxe Clothing #45          │ │ Order #4592: 650K    │ │
│ │    Qty: 12 | Rev: 180K         │ │ Order #4601: 580K    │ │
│ └─────────────────────────────────┘ └───────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

### Component Details

#### Hourly Sales Area Chart
**Type:** Area Chart with gradient fill  
**X-Axis:** 24 hours (00:00 to 23:00)  
**Y-Axis:** Sales amount (0 to 100K)  
**Fill:** Gradient from blue to transparent  
**Line:** Blue, 2px  
**Peak Annotation:** Red dot at 14:00 with label "Peak: 95K RWF"

#### Sales by User Bar Chart
**Type:** Horizontal Bar Chart  
**Bars:** Different color per user  
**Include:** User avatar circle next to name  
**Show:** Order count + revenue amount  
**Interactive:** Click to see user details

---

## Dashboard 3: Inventory Management Dashboard

### Layout

```
┌─────────────────────────────────────────────────────────────────┐
│ INVENTORY MANAGEMENT | Last Update: 2 mins ago    [🔄 Refresh] │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐          │
│ │ LOW STOCK│ │ OUT OF   │ │ TOTAL    │ │ TURNOVER │          │
│ │ ⚠ 12     │ │ STOCK 3  │ │ VALUE    │ │ 8.2x     │          │
│ │ Items    │ │ Items    │ │ 45.2M RWF│ │ Yearly   │          │
│ └──────────┘ └──────────┘ └──────────┘ └──────────┘          │
│                                                                 │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ CRITICAL: PRODUCTS BELOW REORDER LEVEL                      │ │
│ │                                                             │ │
│ │ Product Name         | Stock | Reorder | Deficit | Action │ │
│ │ Premium Electronics  |   2   |   10    |    8    | [Order]│ │
│ │ Standard Clothing    |   5   |   15    |   10    | [Order]│ │
│ │ Deluxe Food Item     |   3   |   20    |   17    | [Order]│ │
│ └─────────────────────────────────────────────────────────────┘ │
│                                                                 │
│ ┌─────────────────────────────────┐ ┌───────────────────────┐ │
│ │ STOCK MOVEMENT (30 Days)       │ │ INVENTORY BY CATEGORY │ │
│ │                                 │ │                       │ │
│ │   [Stacked Bar Chart]          │ │ [Tree Map]           │ │
│ │   Green: Additions              │ │ Electronics: 15.2M   │ │
│ │   Red: Deductions               │ │ Clothing: 12.8M      │ │
│ │   Blue: Adjustments             │ │ Food: 10.5M         │ │
│ └─────────────────────────────────┘ └───────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

### Key Features

#### Critical Alerts Table
- **Color Coding:** Red background for deficit > 15, Orange for 10-15, Yellow for 5-10
- **Action Buttons:** Blue "Order" buttons trigger restock procedure
- **Real-time:** Updates every 5 minutes
- **Sorting:** Click column headers to sort

#### Stock Movement Chart
**Type:** Stacked Column Chart  
**Shows:** Daily stock changes over 30 days  
**Segments:** Additions (Green), Deductions (Red), Adjustments (Blue), Returns (Yellow), Damage (Gray)  
**Tooltip:** Hover shows exact quantities and reasons

---

## Dashboard 4: Audit & Compliance Dashboard

### Layout

```
┌─────────────────────────────────────────────────────────────────┐
│ AUDIT & COMPLIANCE | Security Level: HIGH     [🔒 Settings]    │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐          │
│ │ TOTAL OPS│ │ ALLOWED  │ │ DENIED   │ │COMPLIANCE│          │
│ │   247    │ │   235    │ │ ⚠ 12     │ │  100%    │          │
│ │ Today    │ │  95.1%   │ │  4.9%    │ │ ✓ PASS   │          │
│ └──────────┘ └──────────┘ └──────────┘ └──────────┘          │
│                                                                 │
│ ┌─────────────────────────────────┐ ┌───────────────────────┐ │
│ │ OPERATION TIMELINE (24h)       │ │ WEEKDAY VIOLATIONS    │ │
│ │                                 │ │                       │ │
│ │   [Timeline Chart]             │ │ ⚠ 12 attempts        │ │
│ │   Green: Allowed                │ │ Last: 2 hours ago    │ │
│ │   Red: Denied                   │ │                       │ │
│ │   Yellow: Errors                │ │ [List of attempts]   │ │
│ └─────────────────────────────────┘ │ • 10:15 AM - User 5  │ │
│                                     │ • 11:30 AM - User 8  │ │
│ ┌─────────────────────────────────┐ │ • 02:45 PM - User 5  │ │
│ │ USER ACTIVITY LOG               │ └───────────────────────┘ │
│ │                                 │                           │
│ │ Time     | User | Operation     | Status  | IP Address    │ │
│ │ 14:32:15 | John | INSERT ORDERS | DENIED  | 192.168.1.50 │ │
│ │ 14:30:08 | Marie| UPDATE PRODS  | DENIED  | 192.168.1.42 │ │
│ │ 10:15:22 | Peter| INSERT ORDERS | ALLOWED | 192.168.1.35 │ │
│ └─────────────────────────────────┘                           │
└─────────────────────────────────────────────────────────────────┘
```

### Security Features

#### Operation Timeline
**Type:** Time-series bubble chart  
**X-Axis:** 24 hours  
**Y-Axis:** Operation types  
**Bubbles:** Size represents number of operations  
**Colors:** Green (allowed), Red (denied), Yellow (error)  
**Interactive:** Click bubble to see details

#### User Activity Log
**Type:** Real-time table  
**Auto-refresh:** Every 10 seconds  
**Features:**
- Color-coded status (Green: Allowed, Red: Denied, Orange: Error)
- IP geolocation on hover
- Click row to see full audit details
- Export button for compliance reports

---

## Dashboard 5: Customer Service Dashboard

### Layout

```
┌─────────────────────────────────────────────────────────────────┐
│ CUSTOMER SERVICE | Queue: 5 Pending           [📧 Notifications]│
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐          │
│ │ AVG RATING │ PENDING  │ │ RESPONSE │ │ COMPLAINTS│          │
│ │ ⭐ 4.2/5.0│ FEEDBACK │ │ TIME     │ │ ⚠ 3      │          │
│ │ ↑ +0.3   │    5     │ │ 4.2 hrs  │ │ This Week│          │
│ └──────────┘ └──────────┘ └──────────┘ └──────────┘          │
│                                                                 │
│ ┌─────────────────────────────────┐ ┌───────────────────────┐ │
│ │ RATING TREND (3 Months)        │ │ RECENT FEEDBACK       │ │
│ │                                 │ │                       │ │
│ │   [Line Chart]                 │ │ ⭐⭐⭐⭐⭐ "Excellent!" │ │
│ │   Shows improvement             │ │ Order #4567 (2h ago) │ │
│ │   Target: 4.5                   │ │                       │ │
│ │                                 │ │ ⭐⭐ "Delayed delivery"│ │
│ └─────────────────────────────────┘ │ Order #4589 (5h ago) │ │
│                                     │ [Respond] [Resolve]  │ │
│ ┌─────────────────────────────────┐ └───────────────────────┘ │
│ │ COMMON ISSUES (Word Cloud)      │                           │
│ │                                 │                           │
│ │   DELIVERY  quality  PACKAGING  │                           │
│ │      price    SERVICE           │                           │
│ │   damage   STOCK  support       │                           │
│ └─────────────────────────────────┘                           │
└─────────────────────────────────────────────────────────────────┘
```

### Interactive Elements

#### Recent Feedback Cards
**Style:** Card-based layout  
**Each Card Shows:**
- Star rating (visual stars)
- Customer name and order ID
- Comment excerpt (first 100 chars)
- Time ago (e.g., "2 hours ago")
- Action buttons: "Respond", "Resolve", "View Order"
- Status indicator: Pending (Orange), Responded (Green)

**Hover Effect:** Card lifts with shadow  
**Click:** Opens detailed feedback modal

---

## Dashboard 6: Financial Dashboard

### Layout

```
┌─────────────────────────────────────────────────────────────────┐
│ FINANCIAL OVERVIEW | Dec 2024                [📊 Export] [⚙]   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐          │
│ │ REVENUE  │ │ PAID     │ │ PENDING  │ │ FAILED   │          │
│ │ 42.5M    │ │ 40.2M    │ │ 2.1M     │ │ 200K     │          │
│ │ This Month│ │ 94.6%    │ │ 4.9%     │ │ 0.5%     │          │
│ └──────────┘ └──────────┘ └──────────┘ └──────────┘          │
│                                                                 │
│ ┌─────────────────────────────────┐ ┌───────────────────────┐ │
│ │ PAYMENT METHODS                 │ │ DAILY COLLECTIONS     │ │
│ │                                 │ │                       │ │
│ │   [Pie Chart]                  │ │ [Column Chart]       │ │
│ │   Mobile Money: 45%             │ │ Shows last 30 days   │ │
│ │   Credit Card: 30%              │ │ Peak on payday       │ │
│ │   Bank Transfer: 15%            │ │                       │ │
│ │   Cash: 10%                     │ └───────────────────────┘ │
│ └─────────────────────────────────┘                           │
│                                                                 │
│ ┌─────────────────────────────────────────────────────────────┐ │
│ │ OUTSTANDING PAYMENTS                                         │ │
│ │                                                             │ │
│ │ Order ID | Customer | Amount | Days Old | Status | Action │ │
│ │ #4589    | Alice M. | 125K   | 5 days   | Pending| [Remind]│ │
│ │ #4601    | John U.  | 85K    | 3 days   | Pending| [Remind]│ │
│ └─────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

---

## General Dashboard Features

### Common Elements Across All Dashboards

#### Header Bar
- Logo (left): ShopSmart Rwanda
- Dashboard title (center-left)
- User menu (right): Avatar + Name + Dropdown
- Notifications icon with badge count
- Settings/Gear icon
- Help/Documentation icon

#### Navigation Sidebar (Left, Collapsible)
- Dashboard icon + "Executive Summary"
- Graph icon + "Sales Performance"
- Box icon + "Inventory Management"
- Shield icon + "Audit & Compliance"
- Chat icon + "Customer Service"
- Money icon + "Financial Overview"
- Settings icon + "System Settings"

#### Footer
- Last updated timestamp
- Data refresh indicator
- Export options (PDF, Excel, CSV)
- Print button
- Share dashboard button

### Responsive Behavior
- **Desktop (1920px+):** Full layout as shown
- **Laptop (1366px):** Slightly compressed, 2-column grid
- **Tablet (1024px):** Single column, cards stack
- **Mobile (768px):** Mobile-optimized cards, hamburger menu

### Interactive Features
- **Hover:** All charts show tooltips with detailed info
- **Click:** Cards and chart elements are clickable for drill-down
- **Drag:** Dashboard widgets can be rearranged (optional)
- **Filter:** Date range picker in top-right
- **Search:** Global search bar for quick access
- **Refresh:** Manual refresh button + auto-refresh every 5 minutes

---

## Creating Mockups - Step-by-Step

### Option 1: PowerPoint
1. Set slide size to 1920x1080 (16:9)
2. Insert shapes for cards (Rectangle: Rounded Corners)
3. Use SmartArt for charts or insert from Excel
4. Apply shadows: Format Shape → Shadow → Outer
5. Use color scheme consistently
6. Export as PNG: File → Export → Change File Type → PNG

### Option 2: Figma (Recommended)
1. Create new frame: 1920x1080px
2. Use plugins: Charts, Iconify for icons
3. Create components for reusable cards
4. Use Auto Layout for responsive grids
5. Export: Select frame → Export → PNG 2x

### Option 3: Canva
1. Custom dimensions: 1920x1080px
2. Use Canva Pro for charts
3. Apply brand colors
4. Download as PNG (high quality)

---

**Mockup Files to Create:**
1. `executive_dashboard.png` (1920x1080, 72dpi)
2. `sales_dashboard.png`
3. `inventory_dashboard.png`
4. `audit_dashboard.png`
5. `customer_service_dashboard.png`
6. `financial_dashboard.png`

**Each file should be:**
- High resolution (at least 1920x1080)
- Professional appearance
- Consistent branding
- Clear, readable text
- Realistic data values

---
