// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @title CourseCompletionNFT
 * @dev Issue a single NFT only after a user completes an entire course. 
 * Provides an on-chain, verifiable proof of achievement storing course details.
 */
contract CourseCompletionNFT is ERC721URIStorage, Ownable {
    using Strings for uint256;

    uint256 private _nextTokenId;

    struct CourseInfo {
        string courseName;
        uint256 completionDate;
        string skillsLearned;
    }

    // Mapping from token ID to course info
    mapping(uint256 => CourseInfo) public certificateDetails;
    
    // Mapping to track if a student has already minted this course's certificate
    mapping(address => mapping(string => bool)) public hasMinted;

    event CertificateMinted(address indexed student, uint256 indexed tokenId, string courseName);

    constructor() ERC721("Course Completion Certificate", "CERT") Ownable(msg.sender) {}

    /**
     * @dev Mint a certificate to a student after they finish a course.
     * Can only be called by the contract owner (or authorized platform relayer).
     */
    function mintCertificate(
        address student,
        string memory courseName,
        string memory skillsLearned
    ) external onlyOwner {
        require(!hasMinted[student][courseName], "Student already minted certificate for this course");

        uint256 tokenId = _nextTokenId++;
        _safeMint(student, tokenId);

        certificateDetails[tokenId] = CourseInfo({
            courseName: courseName,
            completionDate: block.timestamp,
            skillsLearned: skillsLearned
        });
        
        hasMinted[student][courseName] = true;

        // Generate dynamic On-Chain SVG & JSON Metadata
        string memory tokenUri = _generateTokenURI(tokenId, courseName, skillsLearned);
        _setTokenURI(tokenId, tokenUri);

        emit CertificateMinted(student, tokenId, courseName);
    }

    /**
     * @dev Internal function to generate base64 encoded JSON metadata with an SVG image representation
     */
    function _generateTokenURI(uint256 tokenId, string memory courseName, string memory skillsLearned) internal view returns (string memory) {
        string memory svg = string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 400 500" style="background:#0c0c12;font-family:monospace;color:#fff;">',
                '<rect width="100%" height="100%" fill="#0c0c12"/>',
                '<path d="M0 0h400v500H0z" fill="url(#grad)"/>',
                '<defs><linearGradient id="grad" x1="0%" y1="0%" x2="100%" y2="100%">',
                '<stop offset="0%" style="stop-color:#00d4ff;stop-opacity:0.2" />',
                '<stop offset="100%" style="stop-color:#8b5cf6;stop-opacity:0.2" />',
                '</linearGradient></defs>',
                '<text x="50%" y="20%" dominant-baseline="middle" text-anchor="middle" font-size="24" fill="#00d4ff" font-weight="bold">Certificate of Completion</text>',
                '<text x="50%" y="40%" dominant-baseline="middle" text-anchor="middle" font-size="18" fill="#fff">', courseName, '</text>',
                '<text x="50%" y="60%" dominant-baseline="middle" text-anchor="middle" font-size="14" fill="#a1a1aa">Skills: ', skillsLearned, '</text>',
                '<text x="50%" y="80%" dominant-baseline="middle" text-anchor="middle" font-size="12" fill="#52525b">Issued: ', block.timestamp.toString(), '</text>',
                '<text x="50%" y="90%" dominant-baseline="middle" text-anchor="middle" font-size="12" fill="#52525b">Token ID: ', tokenId.toString(), '</text>',
                '</svg>'
            )
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "', courseName, ' Certificate",',
                        '"description": "On-chain achievement for completing ', courseName, '",',
                        '"attributes": [{"trait_type": "Skills", "value": "', skillsLearned, '"}],',
                        '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(svg)), '"}'
                    )
                )
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", json));
    }

    /**
     * @dev Optional: Override to make Soulbound (Non-transferable). 
     * In a true PoC, SBTs restrict transfer so users cannot sell their achievements.
     */
    function _update(address to, uint256 tokenId, address auth) internal virtual override returns (address) {
        address from = _ownerOf(tokenId);
        require(from == address(0) || to == address(0), "Course Certificates are Soulbound and non-transferable");
        return super._update(to, tokenId, auth);
    }
}
