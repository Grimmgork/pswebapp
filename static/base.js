function Hello() {
    const request = new XMLHttpRequest();
    const url = "/hello";
    request.open("GET", url);
    request.send();
}

function Bye() {
    const request = new XMLHttpRequest();
    const url = "/bye";
    request.open("GET", url);
    request.send();
}

window.addEventListener('beforeunload', Bye);
Hello();