    
function menuResponsive(){
    document.addEventListener('DOMContentLoaded', function () {
        var menuResponsive = document.getElementById('menu-responsive');
        var escuro = document.querySelector(".escuro");
        var body = document.getElementById("body");
        var toggleSandwich = document.getElementById('toogle_Sandwich');
        var closeMenu = document.getElementById('close-menu-responsive');

        toggleSandwich.addEventListener('click', function () {
            escuro.style.backgroundColor= "rgba(0, 0, 0, 0.7)";
            escuro.style.zIndex= 1000;
            menuResponsive.classList.add('active');
            menuResponsive.style.pointerEvents = 'all';
            body.style.overflow="hidden";
        });

        closeMenu.addEventListener('click', function () {
            escuro.style.backgroundColor="transparent";
            escuro.style.zIndex= 0;
            menuResponsive.style.pointerEvents = 'none';
            menuResponsive.classList.remove('active');
            body.style.overflowY="auto";
        });
    });
}

menuResponsive()

/* Este codigo faz com que quando clicado do toogle switch a div escuro fique com um preto meio transparente , fica com um zindex a 100 
para ficar por cima dos restantes elementos menos do menu-responsivo. é adicionado uma class ao menu-responsive para que este mostre o menu lateral.

Este codigo tambem tem um funcao em que quando clidado no botao dentro do menu-responsive de fechar ele mete o escuro a transparente o zIndex a 0 para
ficar por baixo dos elementos e remove a class adicionada para que o menu lateral desapareca.*/

function buttonDonate(){
    var containerDonate = document.getElementById("containerDonate");
    var buttonDonate = document.getElementById("menu-item5");
    var body = document.getElementById("body");
    var buttonDonateResponsive = document.getElementById("button-menu-responsive");
    var escuro = document.querySelector(".escuro");
    var containerMenuResponsive = document.getElementById("container-menu-responsive");

    buttonDonate.addEventListener("click", function(){
        containerDonate.style.display="block";
        body.style.overflow="hidden";
        escuro.style.backgroundColor= "rgba(0, 0, 0, 0.7)";
        escuro.style.zIndex= 1000;
        containerMenuResponsive.style.overflow="hidden";
    });
    buttonDonateResponsive.addEventListener("click", function(){
        containerDonate.style.display="block";
        body.style.overflow="hidden";
        escuro.style.backgroundColor= "rgba(0, 0, 0, 0.7)";
        escuro.style.zIndex= 1004;
        containerMenuResponsive.style.overflow="hidden";
    });
}



let devolve2=buttonDonate();
console.log(devolve2);
function donation(){
        console.log(devolve2);
        var buttonOnce = document.getElementById("once");
        var buttonMonthly = document.getElementById("monthly");
        var paymentsOnce = document.getElementById("payments-once");
        var paymentsMonthly = document.getElementById("payments-monthly");
        var buttonParticular = document.getElementById("button-particular");
        var buttonCompany = document.getElementById("button-company");
        var particularInformation = document.getElementById("particular-information");
        var companyInformation = document.getElementById("company-information");
        var amount20 = document.getElementById("20");
        var amount40 = document.getElementById("40");
        var amount80 = document.getElementById("80");
        var amountOther = document.getElementById("other");
        var adress = document.getElementById("adress");

        var containerMenuResponsive = document.getElementById("container-menu-responsive");
        var escuro = document.querySelector(".escuro");
        var body = document.getElementById("body");

        var containerDonate = document.getElementById("containerDonate");

        var onceCreditCard = document.getElementById("once-C");
        var oncePaypal = document.getElementById("once-P");
        var onceATM= document.getElementById("once-A");
        var onceMbway = document.getElementById("once-M");

        var monthlyCreditCard = document.getElementById("monthly-C");
        var monthlyDeditCard = document.getElementById("monthly-D");

        var closeDonate = document.getElementById("close");

        var textarea = document.getElementById("text");
        var textLabel= document.getElementById("textLabel");

        var email = document.getElementById("emailInput");
        var nameP = document.getElementById('inputNameParticular');
        var surnameP = document.getElementById('inputSurnameParticular');
        var numberP = document.getElementById('inputNumberParticular');
        var nifP = document.getElementById('inputNIFParticular');

        var nameC = document.getElementById('inputNameCompany');
        var numberC = document.getElementById('inputNumberCompany');
        var nifC = document.getElementById('inputNifCompany');
        var addressC = document.getElementById('adress');

        closeDonate.addEventListener("click", function(){
            email.value = '';
            nameP.value = '';
            surnameP.value = '';
            numberP.value = '';
            nifP.value = '';
            nameC.value = '';
            numberC.value = '';
            nifC.value = '';
            addressC.value = '';
            buttonMonthly.classList.remove("active-type");
            textarea.style.border= "3px solid gray";
            textarea.style.boxShadow= "1px 0px 2px  #232222";
            textLabel.innerHTML="";
            buttonOnce.classList.add("active-type");
            paymentsOnce.style.display="flex";
            adress.style.display="none";
            body.style.overflowY="auto";
            escuro.style.backgroundColor="transparent";
            escuro.style.zIndex= 0;
            containerMenuResponsive.style.overflowY="auto";
            console.log("2");
            buttonCompany.classList.remove("active-information");
            buttonParticular.classList.remove("active-information");
            paymentsMonthly.style.display="none";
            particularInformation.style.display="none";
            companyInformation.style.display="none";
            companyInformation.style.display="none";
            amount20.classList.add("active-amount");
            amount40.classList.remove("active-amount");
            amount80.classList.remove("active-amount");
            amountOther.classList.remove("active-amount");
            onceCreditCard.classList.add("active-payment-once");
            onceATM.classList.remove("active-payment-once");
            oncePaypal.classList.remove("active-payment-once");
            onceMbway.classList.remove("active-payment-once");
            monthlyCreditCard.classList.add("active-payment-monthly");
            containerDonate.style.display="none";
            monthlyDeditCard.classList.remove("active-payment-monthly");

        });

        buttonOnce.addEventListener("click", function(){
            buttonOnce.classList.add("active-type");
            buttonMonthly.classList.remove("active-type");
            paymentsMonthly.style.display="none";
            paymentsOnce.style.display="flex";
            adress.style.display="none";
        });

        buttonMonthly.addEventListener("click", function(){
            buttonMonthly.classList.add("active-type");
            buttonOnce.classList.remove("active-type");
            paymentsOnce.style.display="none";
            paymentsMonthly.style.display="flex";
            adress.style.display="block";
        });

        buttonParticular.addEventListener("click", function(){
            buttonParticular.classList.add("active-information");
            buttonCompany.classList.remove("active-information");
            particularInformation.style.display="flex";
            companyInformation.style.display="none";
        });

        buttonCompany.addEventListener("click", function(){
            buttonParticular.classList.remove("active-information");
            buttonCompany.classList.add("active-information");
            particularInformation.style.display="none";
            companyInformation.style.display="flex";

        });

        amount20.addEventListener("click", function(){
            amount20.classList.add("active-amount");
            amount40.classList.remove("active-amount");
            amount80.classList.remove("active-amount");
            amountOther.classList.remove("active-amount");

        });
        amount40.addEventListener("click", function(){
            amount20.classList.remove("active-amount");
            amount40.classList.add("active-amount");
            amount80.classList.remove("active-amount");
            amountOther.classList.remove("active-amount");

        });
        
        amount80.addEventListener("click", function(){
            amount20.classList.remove("active-amount");
            amount40.classList.remove("active-amount");
            amount80.classList.add("active-amount");
            amountOther.classList.remove("active-amount");

        });
        
        amountOther.addEventListener("click", function(){
            amount20.classList.remove("active-amount");
            amount40.classList.remove("active-amount");
            amount80.classList.remove("active-amount");
            amountOther.classList.add("active-amount");
        });
        
        onceCreditCard.addEventListener("click", function(){
            onceCreditCard.classList.add("active-payment-once");
            onceATM.classList.remove("active-payment-once");
            oncePaypal.classList.remove("active-payment-once");
            onceMbway.classList.remove("active-payment-once");
            monthlyCreditCard.classList.remove("active-payment-monthly");
            monthlyDeditCard.classList.remove("active-payment-monthly");
        });

        oncePaypal.addEventListener("click", function(){
            onceCreditCard.classList.remove("active-payment-once");
            onceATM.classList.remove("active-payment-once");
            oncePaypal.classList.add("active-payment-once");
            onceMbway.classList.remove("active-payment-once");
            monthlyCreditCard.classList.remove("active-payment-monthly");
            monthlyDeditCard.classList.remove("active-payment-monthly");
        });

        onceATM.addEventListener("click", function(){
            onceCreditCard.classList.remove("active-payment-once");
            onceATM.classList.add("active-payment-once");
            oncePaypal.classList.remove("active-payment-once");
            onceMbway.classList.remove("active-payment-once");
            monthlyCreditCard.classList.remove("active-payment-monthly");
            monthlyDeditCard.classList.remove("active-payment-monthly");
        });

        onceMbway.addEventListener("click", function(){
            onceCreditCard.classList.remove("active-payment-once");
            onceATM.classList.remove("active-payment-once");
            oncePaypal.classList.remove("active-payment-once");
            onceMbway.classList.add("active-payment-once");
            monthlyCreditCard.classList.remove("active-payment-monthly");
            monthlyDeditCard.classList.remove("active-payment-monthly");
        });

        monthlyCreditCard.addEventListener("click", function(){
            onceCreditCard.classList.remove("active-payment-once");
            onceATM.classList.remove("active-payment-once");
            oncePaypal.classList.remove("active-payment-once");
            onceMbway.classList.remove("active-payment-once");
            monthlyCreditCard.classList.add("active-payment-monthly");
            monthlyDeditCard.classList.remove("active-payment-monthly");
        });

        monthlyDeditCard.addEventListener("click", function(){
            onceCreditCard.classList.remove("active-payment-once");
            onceATM.classList.remove("active-payment-once");
            oncePaypal.classList.remove("active-payment-once");
            onceMbway.classList.remove("active-payment-once");
            monthlyCreditCard.classList.remove("active-payment-monthly");
            monthlyDeditCard.classList.add("active-payment-monthly");
        });
}

donation();

function validationDonateInformations(){
    var email = document.getElementById("emailInput").value;
    var emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

    var textarea = document.getElementById("text");
    var textLabel= document.getElementById("textLabel");

    var activeInformationElement = document.querySelector('.active-information');

    var nameP = document.getElementById('inputNameParticular').value;
    var surnameP = document.getElementById('inputSurnameParticular').value;
    var numberP = document.getElementById('inputNumberParticular').value;
    var nifP = document.getElementById('inputNIFParticular').value;

    var nameC = document.getElementById('inputNameCompany').value;
    var numberC = document.getElementById('inputNumberCompany').value;
    var nifC = document.getElementById('inputNifCompany').value;
    var addressC = document.getElementById('adress');

    var activeTypeElement = document.querySelector('.active-type');

    ibanValue = document.getElementById("IBAN");

    // Check if email is valid
    if (emailRegex.test(email)) {
        if (activeInformationElement) {
            if(activeInformationElement.value == "Particular"){
                if (nameP.trim() === '' || !/^[A-Za-z]+$/.test(nameP) || surnameP.trim() === '' || !/^[A-Za-z]+$/.test(surnameP) || numberP.trim() === '' || nifP.trim() === '') {
                    // Element does not exist, you can handle this case as needed
                    textarea.style.border= "2px solid red";
                    textarea.style.boxShadow= "2px 10px 2px red";
                    textLabel.innerHTML="Please fill in all fields with valid data. -> Particular Option";
                } else {
                    return 1;
                }
            }else if(activeInformationElement.value == "Company"){

                if (nameC.trim() === '' || !/^[A-Za-z]+$/.test(nameC) || numberC.trim() === '' || nifC.trim() === '') {
                    textarea.style.border= "2px solid red";
                    textarea.style.boxShadow= "2px 10px 2px red";
                    textLabel.innerHTML="Please fill in all fields with valid data. ->  Company Option";
                } else {
                    if(activeTypeElement.value == "Monthly"){
                        if(addressC.value === ''){
                            textarea.style.border= "2px solid red";
                            textarea.style.boxShadow= "2px 10px 2px red";
                            textLabel.innerHTML="Please fill in all fields with valid data. ->  Company Option";
                        }else{
                            return 1;
                        }
                    }else{
                        return 1;
                    }
                }

            }
        } else {
            // Element does not exist, you can handle this case as needed
            textarea.style.border= "2px solid red";
            textarea.style.boxShadow= "2px 10px 2px red";
            textLabel.innerHTML="Choose a option Particular or Company";
        }

    } else {
        // Email is not valid, you can handle this case as needed
        //alert('Invalid email. Please enter a valid email address.');
        textarea.style.border= "2px solid red";
        textarea.style.boxShadow= "2px 10px 2px red";
        textLabel.innerHTML="Invalid email. Please enter a valid email address.";
    }
    
}  

function TextFinal(){
    var activeAmountElement = document.querySelector('.active-amount').value;
    var activeTypeElement = document.querySelector('.active-type').value;
    var textLabel= document.getElementById("textLabel");
    var nRefeicoesP = activeAmountElement/1.5;
    var nPessoasP = (activeAmountElement/1.5)/2;

    var nPessoasDiariamenteC= (activeAmountElement/1.5)/2;

    var nPessoasMensalC = activeAmountElement/(1.5*2*30);

    if(activeTypeElement == "Once"){
        if(activeAmountElement <= 40){
            textLabel.innerHTML="O seu donativo permitirá fornecer aproximadamente " + Math.trunc(nRefeicoesP) +  " refeições.";
        }else{
            textLabel.innerHTML = "";
            textLabel.innerHTML="O seu donativo permitirá fornecer aproximadamente " + Math.trunc(nRefeicoesP) +  " refeições" + " e permitirá alimentar diariamente  "+ Math.trunc(nPessoasP) +" pessoas.";
        }
    }else if(activeTypeElement == "Monthly"){
        if(activeAmountElement <= 90){
            textLabel.innerHTML="O seu donativo permitirá alimentar uma pessoa durante " + Math.trunc(nPessoasDiariamenteC) +  " dias.";
        }else{
            textLabel.innerHTML = "";
            textLabel.innerHTML="O seu donativo permitirá alimentar uma pessoa durante " + Math.trunc(nPessoasDiariamenteC) +  " dias" + " ou permitirá alimentar "+ Math.trunc(nPessoasMensalC) +" pessoas durante este mes.";
        }
    }
}

var buttonConfirm = document.getElementById("confirmButton");
var textarea = document.getElementById("text");
var textLabel= document.getElementById("textLabel");

buttonConfirm.addEventListener("click", function(){
    var validation = validationDonateInformations();
    console.log(validation);
    if(validation == 1){
        textarea.style.border= "2px solid green";
        textarea.style.boxShadow= "2px 10px 2px green";
        textLabel.style.innerHTML= "";
        TextFinal();
    }
});