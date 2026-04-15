// SPDX-License-Identifier: Custom-License
/*This contract is part of Nickelium Token Ecosystem and is property of Destrier LLC. You are granted permission to use all functions of this contract intended for users. 
*However, copying, modifying, or distributing the code is strictly prohibited without explicit permission from the author.
*All rights reserved. Destrier LLC, registration number 20241316871 , Colorado , USA.*/
pragma solidity ^0.8.34;

library SimpleBase64 {
    string internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    
    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";
        
        uint256 encodedLen = 4 * ((data.length + 2) / 3);
        bytes memory result = new bytes(encodedLen);
        
        for (uint256 i = 0; i < data.length; i += 3) {
            uint256 a = uint256(uint8(data[i]));
            uint256 b = i + 1 < data.length ? uint256(uint8(data[i + 1])) : 0;
            uint256 c = i + 2 < data.length ? uint256(uint8(data[i + 2])) : 0;
            
            uint256 triple = (a << 16) | (b << 8) | c;
            
            uint256 j = (i / 3) * 4;
            result[j] = bytes(TABLE)[(triple >> 18) & 0x3F];
            result[j + 1] = bytes(TABLE)[(triple >> 12) & 0x3F];
            result[j + 2] = i + 1 < data.length ? bytes(TABLE)[(triple >> 6) & 0x3F] : bytes1("=");
            result[j + 3] = i + 2 < data.length ? bytes(TABLE)[triple & 0x3F] : bytes1("=");
        }
        
        return string(result);
    }
}

/**
 * @title Proof of Reserves Summary - Delivery Only Version with Origin Tracking
 * @notice Lateritic Nickel Ore Deposits - Central Greece Mining District
 * @dev Dynamic Data - Delivery totals calculated automatically with Land/Sea/Finance categorization
 * @author Kostopoulos (2024-2026), Internal Reports to Destrier LLC
 */
contract ProofOfReservesSummary {

    // ============================================
    // ACCESS CONTROL
    // ============================================

    address public owner;
    mapping(address => bool) public authorizedUsers;

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyAuthorized() {
        require(msg.sender == owner || authorizedUsers[msg.sender], "Not authorized");
        _;
    }

    // ============================================
    // ENUMS AND DATA STRUCTURES
    // ============================================

    enum OriginType { Land, Sea, Finance }

    struct DeliveryDeposit {
        uint256 id;
        string deposit;
        uint256 volumeM3;
        uint256 density;
        uint256 tonnageT;
        uint256 coPercent;
        uint256 fePercent;
        uint256 niPercent;
        uint256 coT;
        uint256 feT;
        uint256 niT;
        OriginType origin;
        string ipfsLink;
    }

    struct DeliveryInput {
        string deposit;
        uint256 volumeM3;
        uint256 density;
        uint256 tonnageT;
        uint256 coPercent;
        uint256 fePercent;
        uint256 niPercent;
        uint256 coT;
        uint256 feT;
        uint256 niT;
        OriginType origin;
        string ipfsLink;
    }

    // ============================================
    // STATE VARIABLES
    // ============================================
    uint256 public constant ALL_TIME_GRAND_TOTAL = 1000000; // 1,000,000 t Ni

// Add this helper function:
function getAllTimeGrandTotalString() external pure returns (string memory) {
    return string(abi.encodePacked(
        "All Time Grand Total: ", formatNumber(ALL_TIME_GRAND_TOTAL), " t Ni"
    ));
}
    string public constant PROJECT_NAME = "LATERITIC NICKEL ORE DEPOSITS";
    string public constant DISCLAIMER = "Anonymized Data - Real Mine & Synthetic Deposits 1-4";

    string public constant SOURCE = string(abi.encodePacked(
        "Proof of reserves in Nickel tonnes = 186,200 t Ni\r\n",
        "Source: on behalf of Destrier LLC ID 20241316871\r\n",
        "State of Colorado 1942 Broadway St., STE 314C, Boulder, CO 80302\r\n",
        "Colorado, United States of America\r\n",
        "by Dr. DIMITRIOS KOSTOPOULOS Professor of Petrology\r\n",
        "National and Kapodistrian University of Athens\r\n",
        "School of Science Faculty of Geology and Geoenvironment\r\n",
        "Department of Mineralogy and Petrology Head\r\n",
        "Panepistimioupoli, Zographou Athens 15784 GREECE"
    ));

    string public oracleLink = "";
    
    uint256 public totalDeliveredNiT;
    uint256 public landNiTotal;
    uint256 public seaNiTotal;
    uint256 public financeNiTotal;

    DeliveryDeposit[] public deliveries;

    // ============================================
    // EVENTS
    // ============================================

    event MineAdded(uint256 indexed id, string deposit, OriginType origin, uint256 niT, address addedBy);
    event OracleLinkUpdated(string newLink, address updatedBy);
    event AuthorizedUserAdded(address user, address addedBy);
    event AuthorizedUserRemoved(address user, address removedBy);

    // ============================================
    // CONSTRUCTOR
    // ============================================

    constructor() {
        owner = msg.sender;
        authorizedUsers[msg.sender] = true;

        deliveries.push(DeliveryDeposit(1, "Real Mine", 1397475, 330, 4611668, 6, 3125, 84, 2662, 1441153, 38834, OriginType.Land, "https://ipfs.io/ipfs/bafybeifhtdlvodgmwuq3ii4l3pnmnawhp6qbp44k3nqiq2di2mwdxf7isa/"));
        totalDeliveredNiT += 38834;
        landNiTotal += 38834;
        
        deliveries.push(DeliveryDeposit(2, "Synthetic 1", 478975, 330, 1580618, 6, 3144, 101, 917, 496946, 15964, OriginType.Land, "https://ipfs.io/ipfs/bafybeifhtdlvodgmwuq3ii4l3pnmnawhp6qbp44k3nqiq2di2mwdxf7isa/"));
        totalDeliveredNiT += 15964;
        landNiTotal += 15964;
        
        deliveries.push(DeliveryDeposit(3, "Synthetic 2", 823500, 330, 2717550, 9, 3499, 87, 2310, 950871, 23643, OriginType.Land, "https://ipfs.io/ipfs/bafybeifhtdlvodgmwuq3ii4l3pnmnawhp6qbp44k3nqiq2di2mwdxf7isa/"));
        totalDeliveredNiT += 23643;
        landNiTotal += 23643;
        
        deliveries.push(DeliveryDeposit(4, "Synthetic 3", 860175, 330, 2838578, 11, 2899, 94, 3092, 822863, 26635, OriginType.Land, "https://ipfs.io/ipfs/bafybeifhtdlvodgmwuq3ii4l3pnmnawhp6qbp44k3nqiq2di2mwdxf7isa/"));
        totalDeliveredNiT += 26635;
        landNiTotal += 26635;
        
        deliveries.push(DeliveryDeposit(5, "Synthetic 4", 2938050, 330, 9695565, 12, 3026, 84, 11335, 2933844, 81302, OriginType.Land, "https://ipfs.io/ipfs/bafybeifhtdlvodgmwuq3ii4l3pnmnawhp6qbp44k3nqiq2di2mwdxf7isa/"));
        totalDeliveredNiT += 81302;
        landNiTotal += 81302;
    }

    // ============================================
    // ACCESS CONTROL
    // ============================================

    function addAuthorizedUser(address user) external onlyOwner {
        require(user != address(0), "Invalid address");
        authorizedUsers[user] = true;
        emit AuthorizedUserAdded(user, msg.sender);
    }

    function removeAuthorizedUser(address user) external onlyOwner {
        require(user != owner, "Cannot remove owner");
        authorizedUsers[user] = false;
        emit AuthorizedUserRemoved(user, msg.sender);
    }

    // ============================================
    // ORACLE LINK
    // ============================================

    function updateOracleLink(string calldata newLink) external onlyAuthorized {
        oracleLink = newLink;
        emit OracleLinkUpdated(newLink, msg.sender);
    }

    function getOracleLink() external view returns (string memory) {
        return oracleLink;
    }

    // ============================================
    // DYNAMIC MINE ADDITION
    // ============================================

    function addDeliveryMine(DeliveryInput calldata input) external onlyAuthorized returns (uint256 newId) {
        require(totalDeliveredNiT + input.niT <= ALL_TIME_GRAND_TOTAL, "Cannot add mine: would exceed All Time Grand Total limit");
        newId = deliveries.length + 1;
        deliveries.push(DeliveryDeposit(
            newId,
            input.deposit,
            input.volumeM3,
            input.density,
            input.tonnageT,
            input.coPercent,
            input.fePercent,
            input.niPercent,
            input.coT,
            input.feT,
            input.niT,
            input.origin,
            input.ipfsLink
        ));
        
        totalDeliveredNiT += input.niT;
        if (input.origin == OriginType.Land) {
            landNiTotal += input.niT;
        } else if (input.origin == OriginType.Sea) {
            seaNiTotal += input.niT;
        } else if (input.origin == OriginType.Finance) {
            financeNiTotal += input.niT;
        }
        
        emit MineAdded(newId, input.deposit, input.origin, input.niT, msg.sender);
        return newId;
    }

    // ============================================
    // CALCULATION FUNCTIONS
    // ============================================

    function calculateDeliveryTotals() public view returns (uint256 totalVolume, uint256 totalTonnage, uint256 totalCoT, uint256 totalFeT, uint256 totalNiT) {
        for (uint i = 0; i < deliveries.length; i++) {
            totalVolume += deliveries[i].volumeM3;
            totalTonnage += deliveries[i].tonnageT;
            totalCoT += deliveries[i].coT;
            totalFeT += deliveries[i].feT;
            totalNiT += deliveries[i].niT;
        }
        return (totalVolume, totalTonnage, totalCoT, totalFeT, totalNiT);
    }

    function getOriginTotals() external view returns (uint256 land, uint256 sea, uint256 finance) {
        return (landNiTotal, seaNiTotal, financeNiTotal);
    }

    // ============================================
    // DISPLAY FUNCTIONS
    // ============================================

    function originToString(OriginType origin) internal pure returns (string memory) {
        if (origin == OriginType.Land) return "Land";
        if (origin == OriginType.Sea) return "Sea";
        if (origin == OriginType.Finance) return "Finance";
        return "Unknown";
    }

    function getDeliveryRow(uint256 index) external view returns (string memory) {
        require(index < deliveries.length, "Index out of bounds");
        DeliveryDeposit storage d = deliveries[index];

        return string(abi.encodePacked(
            padLeft(uint2str(d.id), 2), " | ",
            padRight(d.deposit, 12), " | ",
            padLeft(formatNumber(d.volumeM3), 10), " m3 | ",
            formatDecimal(d.density, 2), " t/m3 | ",
            padLeft(formatNumber(d.tonnageT), 10), " t | ",
            padLeft(formatDecimal(d.coPercent, 2), 5), " % | ",
            padLeft(formatDecimal(d.fePercent, 2), 6), " % | ",
            padLeft(formatDecimal(d.niPercent, 2), 5), " % | ",
            padLeft(formatNumber(d.coT), 7), " t | ",
            padLeft(formatNumber(d.feT), 10), " t | ",
            padLeft(formatNumber(d.niT), 8), " t | ",
            padRight(originToString(d.origin), 8), " | ",
            d.ipfsLink
        ));
    }

    function getAllDeliveryRows() external view returns (string[] memory) {
        string[] memory rows = new string[](deliveries.length);
        for (uint i = 0; i < deliveries.length; i++) {
            rows[i] = this.getDeliveryRow(i);
        }
        return rows;
    }

    function getDeliveryFooter() external view returns (string memory) {
        (uint256 totalVolume, uint256 totalTonnage, uint256 totalCoT, uint256 totalFeT, uint256 totalNiT) = calculateDeliveryTotals();
        
        return string(abi.encodePacked(
            "TOTAL |              | ",
            padLeft(formatNumber(totalVolume), 10), " m3 |           | ",
            padLeft(formatNumber(totalTonnage), 10), " t |        |         |        | ",
            padLeft(formatNumber(totalCoT), 7), " t | ",
            padLeft(formatNumber(totalFeT), 10), " t | ",
            padLeft(formatNumber(totalNiT), 8), " t |          |"
        ));
    }

    function getDeliveryGrandTotal() external view returns (string memory) {
        return string(abi.encodePacked(
            "Grand Total Delivered: ", formatNumber(totalDeliveredNiT), " t Ni\r\n",
            "  - Land:    ", formatNumber(landNiTotal), " t Ni\r\n",
            "  - Sea:     ", formatNumber(seaNiTotal), " t Ni\r\n",
            "  - Finance: ", formatNumber(financeNiTotal), " t Ni"
        ));
    }

    function getDeliveryHeader() external pure returns (string memory) {
        return "TABLE - DELIVERY";
    }

    function getDeliveryColumnHeader() internal pure returns (string memory) {
        return " # | Deposit      | Volume (m3)   | Density   | Tonnage (t)   | Co (%) |   Fe (%)  | Ni (%) |     Co (t)   |    Fe (t)      |   Ni (t)   | Origin   | IPFS Link";
    }

    function getDeliverySeparator() internal pure returns (string memory) {
        return "---|-----------------|--------------------|-------------|-------------------|-----------|---------------|-----------|-------------|---------------|-----------------|----------|------------------------------------------------------------------";
    }

    function getDelivery(uint256 index) external view returns (DeliveryDeposit memory) {
        require(index < deliveries.length, "Index out of bounds");
        return deliveries[index];
    }

    function getDeliveryCount() external view returns (uint256) {
        return deliveries.length;
    }

    // ============================================
    // FULL REPORT
    // ============================================

    function getFullReport() external view returns (string memory) {
        bytes memory report = bytes("");

        report = abi.encodePacked(report, PROJECT_NAME, "\r\n");
        report = abi.encodePacked(report, DISCLAIMER, "\r\n\r\n");
        report = abi.encodePacked(report, "TABLE - DELIVERY", "\r\n");
        report = abi.encodePacked(report, getDeliveryColumnHeader(), "\r\n");
        report = abi.encodePacked(report, getDeliverySeparator(), "\r\n");

        for (uint i = 0; i < deliveries.length; i++) {
            report = abi.encodePacked(report, this.getDeliveryRow(i), "\r\n");
        }

        report = abi.encodePacked(report, getDeliverySeparator(), "\r\n");
        report = abi.encodePacked(report, this.getDeliveryFooter(), "\r\n");
        report = abi.encodePacked(report, this.getDeliveryGrandTotal(), "\r\n\r\n");
        report = abi.encodePacked(report, this.getAllTimeGrandTotalString(), "\r\n\r\n");
        report = abi.encodePacked(report, SOURCE);

        return string(report);
    }

    function getFullReportBytes() external view returns (bytes memory) {
        return bytes(this.getFullReport());
    }

    // ============================================
    // DATA URI WITH MINING LICENSE
    // ============================================

    function Copy_This_DataURI_Paste_Into_Browser_Then_Save_Page() external view returns (string memory) {
        return getFullReportDataURI();
    }

    function getFullReportDataURI() internal view returns (string memory) {
    string memory part1 = string(abi.encodePacked(
    "<!DOCTYPE html><html><head><meta charset='UTF-8'><style>",
    "body{font-family:monospace;white-space:pre-wrap;padding:20px;background:#f5f5f5;}",
    "pre{background:white;padding:20px;border:1px solid #ddd;overflow-x:auto;}",
    ".banner{background:#4caf50;color:white;padding:20px;margin-bottom:20px;border-radius:5px;font-family:sans-serif;text-align:center;}",
    ".banner h2{margin:0 0 10px 0;}",
    ".banner p{margin:5px 0;}",
    ".mining-license{margin:10px 0;font-family:sans-serif;text-align:center;}",
    ".mining-license a{background:#333;color:white;padding:4px 8px;border-radius:5px;text-decoration:none;display:inline-block;}",
    ".mining-license .no-link{color:#ccc;font-style:italic;}",
    ".grand-total-box{background:#4caf50;color:white;padding:15px;margin:20px 0;border-radius:5px;font-family:sans-serif;text-align:center;font-size:18px;font-weight:bold;}", // ADD THIS LINE
    "kbd{background:#333;color:#fff;padding:2px 6px;border-radius:3px;font-family:monospace;}",
    "table{border-collapse:collapse;width:100%;font-family:monospace;font-size:12px;}",
    "th,td{border:1px solid #ddd;padding:8px;text-align:left;}",
    "th{background-color:#4caf50;color:white;}",
    "tr:nth-child(even){background-color:#f2f2f2;}",
    ".ipfs-link{color:#0066cc;text-decoration:underline;cursor:pointer;}",
    ".ipfs-link:hover{color:#003366;}",
    ".totals{font-weight:bold;background-color:#e8f5e9;}",
    "</style></head><body>",
    "<div class='banner'><h2>Proof of Reserves Report Loaded</h2>",
    "<p><strong>This is a verified on-chain report in metric tonnes for the Nickel as backup asset for Nickelium (1 token equals to 100 hybrid grams of Nickel)</strong></p>",
    "<p>Hybrid Nickel tonnes are calculated dynamically from 20 percent real reserves and 80 percent synthetic reserves</p>",
    "<p>To save this certificate: Press <kbd>Ctrl+S</kbd> (Windows) or <kbd>Cmd+S</kbd> (Mac)</p>"
));
    
    // Add Mining License section right after the save instruction
    string memory miningLicenseSection = getMiningLicenseHTML();
    
    string memory part2 = string(abi.encodePacked(
        "</div>"
    ));
    
    string memory tableHTML = generateHTMLTable();

    string memory grandTotalSection = string(abi.encodePacked(
        "<div class='grand-total-box'>All Time Grand Total: ", formatNumber(ALL_TIME_GRAND_TOTAL), " t Ni</div>"
    ));
    
    string memory fullHTML = string(abi.encodePacked(part1, miningLicenseSection, part2, tableHTML, grandTotalSection, "</body></html>"));
    
    return string(abi.encodePacked(
        "data:text/html;base64,",
        SimpleBase64.encode(bytes(fullHTML))
    ));
}

    function getMiningLicenseHTML() internal view returns (string memory) {
    if (bytes(oracleLink).length == 0) {
        return string(abi.encodePacked(
            "<p class='mining-license'><span class='no-link'>To see the mining license click here (not set)</span></p>"
        ));
    }
    return string(abi.encodePacked(
        "<p class='mining-license'>To see the mining license click <a href='", oracleLink, "' target='_blank' title='Click to view Mining License'>here</a></p>"
    ));
}

    function generateHTMLTable() internal view returns (string memory) {
        string memory table = "<table><tr><th>#</th><th>Deposit</th><th>Volume (m3)</th><th>Density</th><th>Tonnage (t)</th><th>Co (%)</th><th>Fe (%)</th><th>Ni (%)</th><th>Co (t)</th><th>Fe (t)</th><th>Ni (t)</th><th>Origin</th><th>IPFS Proof</th></tr>";
        
        for (uint i = 0; i < deliveries.length; i++) {
            DeliveryDeposit storage d = deliveries[i];
            table = string(abi.encodePacked(
                table,
                "<tr><td>", uint2str(d.id), "</td>",
                "<td>", d.deposit, "</td>",
                "<td>", formatNumber(d.volumeM3), "</td>",
                "<td>", formatDecimal(d.density, 2), "</td>",
                "<td>", formatNumber(d.tonnageT), "</td>",
                "<td>", formatDecimal(d.coPercent, 2), "</td>",
                "<td>", formatDecimal(d.fePercent, 2), "</td>",
                "<td>", formatDecimal(d.niPercent, 2), "</td>",
                "<td>", formatNumber(d.coT), "</td>",
                "<td>", formatNumber(d.feT), "</td>",
                "<td>", formatNumber(d.niT), "</td>",
                "<td>", originToString(d.origin), "</td>",
                "<td><a href='", d.ipfsLink, "' target='_blank' class='ipfs-link'>", d.ipfsLink, "</a></td></tr>"
            ));
        }
        
        (uint256 totalVolume, uint256 totalTonnage, uint256 totalCoT, uint256 totalFeT, uint256 totalNiT) = calculateDeliveryTotals();
        table = string(abi.encodePacked(
            table,
            "<tr class='totals'><td colspan='2'>TOTAL</td>",
            "<td>", formatNumber(totalVolume), "</td>",
            "<td>-</td>",
            "<td>", formatNumber(totalTonnage), "</td>",
            "<td>-</td><td>-</td><td>-</td>",
            "<td>", formatNumber(totalCoT), "</td>",
            "<td>", formatNumber(totalFeT), "</td>",
            "<td>", formatNumber(totalNiT), "</td>",
            "<td colspan='2'>Grand Total: ", formatNumber(totalDeliveredNiT), " t Ni (Land: ", formatNumber(landNiTotal), ", Sea: ", formatNumber(seaNiTotal), ", Finance: ", formatNumber(financeNiTotal), ")</td></tr>"
        ));
        
        table = string(abi.encodePacked(table, "</table>"));
        return table;
    }

    // ============================================
    // UTILITY FUNCTIONS
    // ============================================

    function uint2str(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) return "0";
        uint256 j = _i;
        uint256 len;
        while (j != 0) { len++; j /= 10; }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function padLeft(string memory s, uint256 width) internal pure returns (string memory) {
        bytes memory b = bytes(s);
        if (b.length >= width) return s;
        bytes memory result = new bytes(width);
        uint256 pad = width - b.length;
        for (uint256 i = 0; i < pad; i++) result[i] = " ";
        for (uint256 i = 0; i < b.length; i++) result[pad + i] = b[i];
        return string(result);
    }

    function padRight(string memory s, uint256 width) internal pure returns (string memory) {
        bytes memory b = bytes(s);
        if (b.length >= width) return s;
        bytes memory result = new bytes(width);
        for (uint256 i = 0; i < b.length; i++) result[i] = b[i];
        for (uint256 i = b.length; i < width; i++) result[i] = " ";
        return string(result);
    }

    function formatNumber(uint256 n) internal pure returns (string memory) {
        string memory s = uint2str(n);
        bytes memory b = bytes(s);
        if (b.length <= 3) return s;
        uint256 len = b.length;
        uint256 commas = (len - 1) / 3;
        bytes memory result = new bytes(len + commas);
        uint256 j = result.length;
        uint256 count = 0;
        for (uint256 i = len; i > 0; i--) {
            if (count == 3 && i > 0) {
                j--;
                result[j] = ",";
                count = 0;
            }
            j--;
            result[j] = b[i-1];
            count++;
        }
        return string(result);
    }

    function formatDecimal(uint256 n, uint256 decimals) internal pure returns (string memory) {
        uint256 divisor = 10 ** decimals;
        uint256 whole = n / divisor;
        uint256 frac = n % divisor;
        string memory wholeStr = uint2str(whole);
        string memory fracStr = padLeft(uint2str(frac), decimals);
        return string(abi.encodePacked(wholeStr, ".", fracStr));
    }
}