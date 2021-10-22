pragma solidity ^0.5.4;

contract IExamController {
    event ExamCreated (
        string Subject,
        string Class,
        string Time,
        string Description,
        address Creator,
        address NFTAddress
    );

    event JoinExam (address Exam, address Student, uint256 TokenId);

    function createExam(string memory _subject, string memory _class, string memory _time, string memory _description, uint256 _salt) public returns(address);

    function joinExam(address _examNft, address _student, string memory _action, string memory _from, string memory _to, string memory _description, string memory _date, bytes memory _signature, string memory _uri, uint256 _salt) public;

    function getExamAddress(string memory _subject, string memory _class, string memory _time, string memory _description) public returns(address);
}
