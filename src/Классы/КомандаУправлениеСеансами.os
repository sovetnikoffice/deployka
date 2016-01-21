
///////////////////////////////////////////////////////////////////////////////////////////////////
// Прикладной интерфейс

Перем мНастройки;
Перем Лог;
Перем мИдентификаторКластера;

Процедура ЗарегистрироватьКоманду(Знач ИмяКоманды, Знач Парсер) Экспорт
	
    ОписаниеКоманды = Парсер.ОписаниеКоманды(ИмяКоманды, "Управление сеансами информационной базы");
    
    Парсер.ДобавитьПозиционныйПараметрКоманды(ОписаниеКоманды, "Действие", "lock|unlock");
    Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, "-ras", "Сетевой адрес RAS");
    Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, "-rac", "Команда запуска RAC");
    Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, "-db", "Имя информационной базы");
    
    Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, 
    	"-db-user",
    	"Пользователь информационной базы");

    Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, 
    	"-db-pwd",
    	"Пароль пользователя информационной базы");
        
    Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, 
    	"-cluster-admin",
    	"Администратор кластера");

    Парсер.ДобавитьИменованныйПараметрКоманды(ОписаниеКоманды, 
    	"-cluster-pwd",
    	"Пароль администратора кластера");
    
    Парсер.ДобавитьКоманду(ОписаниеКоманды);
    
КонецПроцедуры

Функция ВыполнитьКоманду(Знач ПараметрыКоманды) Экспорт

    ПрочитатьПараметры(ПараметрыКоманды);
    
    Если Не ПараметрыВведеныКорректно() Тогда
        Возврат МенеджерКомандПриложения.РезультатыКоманд().НеверныеПараметры;
    КонецЕсли;
    
    Если мНастройки.Действие = "lock" Тогда
        УстановитьСтатусБлокировкиСеансов(Истина);
    ИначеЕсли мНастройки.Действие = "unlock" Тогда
        УстановитьСтатусБлокировкиСеансов(Ложь);
    Иначе
        Лог.Ошибка("Неизвестное действие: " + мНастройки.Действие);
        Возврат МенеджерКомандПриложения.РезультатыКоманд().НеверныеПараметры;
    КонецЕсли;

    Возврат МенеджерКомандПриложения.РезультатыКоманд().НеРеализовано;
    
КонецФункции

Процедура ПрочитатьПараметры(Знач ПараметрыКоманды)
    мНастройки = Новый Структура;
    
    Для Каждого КЗ Из ПараметрыКоманды Цикл
        Лог.Отладка(КЗ.Ключ + " = " + КЗ.Значение);
    КонецЦикла;
    
    мНастройки.Вставить("АдресСервераАдминистрирования", ПараметрыКоманды["-ras"]);
    мНастройки.Вставить("ПутьКлиентаАдминистрирования", ПараметрыКоманды["-rac"]);
    мНастройки.Вставить("ИмяБазыДанных", ПараметрыКоманды["-db"]);
    мНастройки.Вставить("АдминистраторИБ", ПараметрыКоманды["-db-user"]);
    мНастройки.Вставить("ПарольАдминистратораИБ", ПараметрыКоманды["-db-pwd"]);
    мНастройки.Вставить("АдминистраторКластера", ПараметрыКоманды["-cluster-admin"]);
    мНастройки.Вставить("ПарольАдминистратораКластера", ПараметрыКоманды["-cluster-pwd"]);
    мНастройки.Вставить("Действие", ПараметрыКоманды["Действие"]);
    
КонецПроцедуры

Функция ПараметрыВведеныКорректно()
    
    Успех = Истина;
    
    Если Не ЗначениеЗаполнено(мНастройки.АдресСервераАдминистрирования) Тогда
        Лог.Ошибка("Не указан сервер администрирования");
        Успех = Ложь;
    КонецЕсли;
    
    Если Не ЗначениеЗаполнено(мНастройки.ПутьКлиентаАдминистрирования) Тогда
        Лог.Ошибка("Не указан клиент администрирования");
        Успех = Ложь;
    КонецЕсли;
    
    Если Не ЗначениеЗаполнено(мНастройки.ИмяБазыДанных) Тогда
        Лог.Ошибка("Не указано имя базы данных");
        Успех = Ложь;
    КонецЕсли;
    
    Если Не ЗначениеЗаполнено(мНастройки.Действие) Тогда
        Лог.Ошибка("Не указано действие lock/unlock");
        Успех = Ложь;
    КонецЕсли;
    
    Возврат Успех;
    
КонецФункции

/////////////////////////////////////////////////////////////////////////////////
// Взаимодействие с кластером

Процедура УстановитьСтатусБлокировкиСеансов(Знач Блокировать)
    
    УИДИБ = НайтиБазуВКластере();
    
    КлючиАвторизацииВБазе = "";
    Если ЗначениеЗаполнено(мНастройки.АдминистраторИБ) Тогда
        КлючиАвторизацииВБазе = КлючиАвторизацииВБазе + СтрШаблон(" --infobase-user=""%1""", мНастройки.АдминистраторИБ);
    КонецЕсли;
    
    Если ЗначениеЗаполнено(мНастройки.ПарольАдминистратораИБ) Тогда
        КлючиАвторизацииВБазе = КлючиАвторизацииВБазе + СтрШаблон(" --infobase-pwd=""%1""", мНастройки.ПарольАдминистратораИБ);
    КонецЕсли;
    
	КомандаВыполнения = СтрокаЗапускаКлиента() + СтрШаблон("infobase update --infobase=""%3""%4 --cluster=""%1""%2 --sessions-deny=%5 --permission-code=""%3""",
        ИдентификаторКластера(),
        КлючиАвторизацииВКластере(),
        УИДИБ,
        КлючиАвторизацииВБазе,
        ?(Блокировать, "on", "off"));
        
    ЗапуститьПроцесс(КомандаВыполнения);
    
    Лог.Информация("Сеансы " + ?(Блокировать, "запрещены", "разрешены"));
    
КонецПроцедуры

Функция ИдентификаторКластера()

    Если мИдентификаторКластера = Неопределено Тогда
        Лог.Информация("Получаю список кластеров");
        
       КомандаВыполнения = СтрокаЗапускаКлиента() + "cluster list";
       
       СписокКластеров = ЗапуститьПроцесс(КомандаВыполнения);
       
       УИДКластера = Сред(СписокКластеров,(Найти(СписокКластеров,":")+1),Найти(СписокКластеров,"host")-Найти(СписокКластеров,":")-1);	
	   мИдентификаторКластера = СокрЛП(СтрЗаменить(УИДКластера,Символы.ПС,""));
        
    КонецЕсли;
    
    Если ПустаяСтрока(мИдентификаторКластера) Тогда
        ВызватьИсключение "Кластер серверов отсутствует";
    КонецЕсли;
    
    Возврат мИдентификаторКластера;

КонецФункции

Функция НайтиБазуВКластере()
    
    КомандаВыполнения = СтрокаЗапускаКлиента() + СтрШаблон("infobase summary list --cluster=""%1""%2",
        ИдентификаторКластера(), 
        КлючиАвторизацииВКластере());

    Лог.Информация("Получаю список баз кластера");
    
    СписокБазВКластере = ЗапуститьПроцесс(КомандаВыполнения);    
	ЧислоСтрок = СтрЧислоСтрок(СписокБазВКластере);
    НайденаБазаВКластере = Ложь;
    Для К = 1 По ЧислоСтрок Цикл
		
		СтрокаРазбора = СтрПолучитьСтроку(СписокБазВКластере,К);   
		ПозицияРазделителя = Найти(СтрокаРазбора,":");
		Если Найти(СтрокаРазбора,"infobase")>0 Тогда						
			УИДИБ =  СокрЛП(Сред(СтрокаРазбора,ПозицияРазделителя+1));	
		ИначеЕсли Найти(СтрокаРазбора,"name")>0 Тогда 
			 ИмяБазы = СокрЛП(Сред(СтрокаРазбора,ПозицияРазделителя+1));
			 Если ИмяБазы = мНастройки.ИмяБазыДанных Тогда
                Сообщить("Получен УИД базы");
                НайденаБазаВКластере = Истина;
                Прервать;
			 КонецЕсли;
		КонецЕсли;
		
	КонецЦикла;
	Если Не НайденаБазаВКластере Тогда
	    ВызватьИсключение "База "+мНастройки.ИмяБазыДанных +" не найдена в кластере";
	КонецЕсли;
    
    Возврат УИДИБ;
    
КонецФункции

Функция КлючиАвторизацииВКластере()
    КомандаВыполнения = "";
    Если ЗначениеЗаполнено(мНастройки.АдминистраторКластера) Тогда
        КомандаВыполнения = КомандаВыполнения + СтрШаблон(" --cluster-user=""%1""", мНастройки.АдминистраторКластера);
    КонецЕсли;
    
    Если ЗначениеЗаполнено(мНастройки.ПарольАдминистратораКластера) Тогда
        КомандаВыполнения = КомандаВыполнения + СтрШаблон(" --cluster-pwd=""%1""", мНастройки.ПарольАдминистратораКластера);
    КонецЕсли;
    Возврат КомандаВыполнения;
КонецФункции

Функция СтрокаЗапускаКлиента()
    Возврат ЗапускПриложений.ОбернутьВКавычки(мНастройки.ПутьКлиентаАдминистрирования) + " " + 
            мНастройки.АдресСервераАдминистрирования + " "; 
КонецФункции

Функция ЗапуститьПроцесс(Знач СтрокаВыполнения)
	
    Лог.Отладка(СтрокаВыполнения);
    
	Процесс = СоздатьПроцесс(СтрокаВыполнения,,Истина);
    Процесс.Запустить();
	Процесс.ОжидатьЗавершения();
    
    Если Процесс.КодВозврата = 0 Тогда
        Текст = Процесс.ПотокВывода.Прочитать();
        Лог.Отладка(Текст);
        Возврат Текст;
    Иначе
        ВызватьИсключение "Сообщение от RAS/RAC 
        |" + Процесс.ПотокОшибок.Прочитать();
    КонецЕсли;	

КонецФункции

/////////////////////////////////////////////////////////////////////////////////

Лог = Логирование.ПолучитьЛог("vanessa.app.deployka");