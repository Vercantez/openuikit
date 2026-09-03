import Foundation

// Public Contacts string constants. Key names match the Apple property-key
// contract. Standard label payloads use the documented `_$!<Label>!$_` form.
// Extended kinship label payloads are portable identifiers of the same form;
// byte-identical Apple strings for those kinship labels remain an oracle item.

public let CNContactBirthdayKey = "birthday"
public let CNContactDatesKey = "dates"
public let CNContactDepartmentNameKey = "departmentName"
public let CNContactEmailAddressesKey = "emailAddresses"
public let CNContactFamilyNameKey = "familyName"
public let CNContactGivenNameKey = "givenName"
public let CNContactIdentifierKey = "identifier"
public let CNContactImageDataAvailableKey = "imageDataAvailable"
public let CNContactImageDataKey = "imageData"
public let CNContactInstantMessageAddressesKey = "instantMessageAddresses"
public let CNContactJobTitleKey = "jobTitle"
public let CNContactMiddleNameKey = "middleName"
public let CNContactNamePrefixKey = "namePrefix"
public let CNContactNameSuffixKey = "nameSuffix"
public let CNContactNicknameKey = "nickname"
public let CNContactNonGregorianBirthdayKey = "nonGregorianBirthday"
public let CNContactNoteKey = "note"
public let CNContactOrganizationNameKey = "organizationName"
public let CNContactPhoneNumbersKey = "phoneNumbers"
public let CNContactPhoneticFamilyNameKey = "phoneticFamilyName"
public let CNContactPhoneticGivenNameKey = "phoneticGivenName"
public let CNContactPhoneticMiddleNameKey = "phoneticMiddleName"
public let CNContactPhoneticOrganizationNameKey = "phoneticOrganizationName"
public let CNContactPostalAddressesKey = "postalAddresses"
public let CNContactPreviousFamilyNameKey = "previousFamilyName"
public let CNContactPropertyAttribute = "CNContactPropertyAttribute"
public let CNContactPropertyNotFetchedExceptionName = "CNContactPropertyNotFetchedExceptionName"
public let CNContactRelationsKey = "contactRelations"
public let CNContactSocialProfilesKey = "socialProfiles"
public let CNContactThumbnailImageDataKey = "thumbnailImageData"
public let CNContactTypeKey = "contactType"
public let CNContactUrlAddressesKey = "urlAddresses"
public let CNContainerIdentifierKey = "identifier"
public let CNContainerNameKey = "name"
public let CNContainerTypeKey = "type"
public let CNErrorDomain = "CNErrorDomain"
public let CNErrorUserInfoAffectedRecordIdentifiersKey = "CNErrorUserInfoAffectedRecordIdentifiersKey"
public let CNErrorUserInfoAffectedRecordsKey = "CNErrorUserInfoAffectedRecordsKey"
public let CNErrorUserInfoKeyPathsKey = "CNErrorUserInfoKeyPathsKey"
public let CNErrorUserInfoValidationErrorsKey = "CNErrorUserInfoValidationErrorsKey"
public let CNGroupIdentifierKey = "identifier"
public let CNGroupNameKey = "name"
public let CNInstantMessageAddressServiceKey = "service"
public let CNInstantMessageAddressUsernameKey = "username"
public let CNInstantMessageServiceAIM = "AIM"
public let CNInstantMessageServiceFacebook = "Facebook"
public let CNInstantMessageServiceGaduGadu = "GaduGadu"
public let CNInstantMessageServiceGoogleTalk = "GoogleTalk"
public let CNInstantMessageServiceICQ = "ICQ"
public let CNInstantMessageServiceJabber = "Jabber"
public let CNInstantMessageServiceMSN = "MSN"
public let CNInstantMessageServiceQQ = "QQ"
public let CNInstantMessageServiceSkype = "Skype"
public let CNInstantMessageServiceYahoo = "Yahoo"
public let CNLabelContactRelationAssistant = "_$!<Assistant>!$_"
public let CNLabelContactRelationAunt = "_$!<Aunt>!$_"
public let CNLabelContactRelationAuntFathersBrothersWife = "_$!<AuntFathersBrothersWife>!$_"
public let CNLabelContactRelationAuntFathersElderBrothersWife = "_$!<AuntFathersElderBrothersWife>!$_"
public let CNLabelContactRelationAuntFathersElderSister = "_$!<AuntFathersElderSister>!$_"
public let CNLabelContactRelationAuntFathersSister = "_$!<AuntFathersSister>!$_"
public let CNLabelContactRelationAuntFathersYoungerBrothersWife = "_$!<AuntFathersYoungerBrothersWife>!$_"
public let CNLabelContactRelationAuntFathersYoungerSister = "_$!<AuntFathersYoungerSister>!$_"
public let CNLabelContactRelationAuntMothersBrothersWife = "_$!<AuntMothersBrothersWife>!$_"
public let CNLabelContactRelationAuntMothersElderSister = "_$!<AuntMothersElderSister>!$_"
public let CNLabelContactRelationAuntMothersSister = "_$!<AuntMothersSister>!$_"
public let CNLabelContactRelationAuntMothersYoungerSister = "_$!<AuntMothersYoungerSister>!$_"
public let CNLabelContactRelationAuntParentsElderSister = "_$!<AuntParentsElderSister>!$_"
public let CNLabelContactRelationAuntParentsSister = "_$!<AuntParentsSister>!$_"
public let CNLabelContactRelationAuntParentsYoungerSister = "_$!<AuntParentsYoungerSister>!$_"
public let CNLabelContactRelationBoyfriend = "_$!<Boyfriend>!$_"
public let CNLabelContactRelationBrother = "_$!<Brother>!$_"
public let CNLabelContactRelationBrotherInLaw = "_$!<BrotherInLaw>!$_"
public let CNLabelContactRelationBrotherInLawElderSistersHusband = "_$!<BrotherInLawElderSistersHusband>!$_"
public let CNLabelContactRelationBrotherInLawHusbandsBrother = "_$!<BrotherInLawHusbandsBrother>!$_"
public let CNLabelContactRelationBrotherInLawHusbandsSistersHusband = "_$!<BrotherInLawHusbandsSistersHusband>!$_"
public let CNLabelContactRelationBrotherInLawSistersHusband = "_$!<BrotherInLawSistersHusband>!$_"
public let CNLabelContactRelationBrotherInLawSpousesBrother = "_$!<BrotherInLawSpousesBrother>!$_"
public let CNLabelContactRelationBrotherInLawWifesBrother = "_$!<BrotherInLawWifesBrother>!$_"
public let CNLabelContactRelationBrotherInLawWifesSistersHusband = "_$!<BrotherInLawWifesSistersHusband>!$_"
public let CNLabelContactRelationBrotherInLawYoungerSistersHusband = "_$!<BrotherInLawYoungerSistersHusband>!$_"
public let CNLabelContactRelationChild = "_$!<Child>!$_"
public let CNLabelContactRelationChildInLaw = "_$!<ChildInLaw>!$_"
public let CNLabelContactRelationCoBrotherInLaw = "_$!<CoBrotherInLaw>!$_"
public let CNLabelContactRelationCoFatherInLaw = "_$!<CoFatherInLaw>!$_"
public let CNLabelContactRelationCoMotherInLaw = "_$!<CoMotherInLaw>!$_"
public let CNLabelContactRelationCoParentInLaw = "_$!<CoParentInLaw>!$_"
public let CNLabelContactRelationCoSiblingInLaw = "_$!<CoSiblingInLaw>!$_"
public let CNLabelContactRelationCoSisterInLaw = "_$!<CoSisterInLaw>!$_"
public let CNLabelContactRelationColleague = "_$!<Colleague>!$_"
public let CNLabelContactRelationCousin = "_$!<Cousin>!$_"
public let CNLabelContactRelationCousinFathersBrothersDaughter = "_$!<CousinFathersBrothersDaughter>!$_"
public let CNLabelContactRelationCousinFathersBrothersSon = "_$!<CousinFathersBrothersSon>!$_"
public let CNLabelContactRelationCousinFathersSistersDaughter = "_$!<CousinFathersSistersDaughter>!$_"
public let CNLabelContactRelationCousinFathersSistersSon = "_$!<CousinFathersSistersSon>!$_"
public let CNLabelContactRelationCousinGrandparentsSiblingsChild = "_$!<CousinGrandparentsSiblingsChild>!$_"
public let CNLabelContactRelationCousinGrandparentsSiblingsDaughter = "_$!<CousinGrandparentsSiblingsDaughter>!$_"
public let CNLabelContactRelationCousinGrandparentsSiblingsSon = "_$!<CousinGrandparentsSiblingsSon>!$_"
public let CNLabelContactRelationCousinMothersBrothersDaughter = "_$!<CousinMothersBrothersDaughter>!$_"
public let CNLabelContactRelationCousinMothersBrothersSon = "_$!<CousinMothersBrothersSon>!$_"
public let CNLabelContactRelationCousinMothersSistersDaughter = "_$!<CousinMothersSistersDaughter>!$_"
public let CNLabelContactRelationCousinMothersSistersSon = "_$!<CousinMothersSistersSon>!$_"
public let CNLabelContactRelationCousinOrSiblingsChild = "_$!<CousinOrSiblingsChild>!$_"
public let CNLabelContactRelationCousinParentsSiblingsChild = "_$!<CousinParentsSiblingsChild>!$_"
public let CNLabelContactRelationCousinParentsSiblingsDaughter = "_$!<CousinParentsSiblingsDaughter>!$_"
public let CNLabelContactRelationCousinParentsSiblingsSon = "_$!<CousinParentsSiblingsSon>!$_"
public let CNLabelContactRelationDaughter = "_$!<Daughter>!$_"
public let CNLabelContactRelationDaughterInLaw = "_$!<DaughterInLaw>!$_"
public let CNLabelContactRelationDaughterInLawOrSisterInLaw = "_$!<DaughterInLawOrSisterInLaw>!$_"
public let CNLabelContactRelationDaughterInLawOrStepdaughter = "_$!<DaughterInLawOrStepdaughter>!$_"
public let CNLabelContactRelationElderBrother = "_$!<ElderBrother>!$_"
public let CNLabelContactRelationElderBrotherInLaw = "_$!<ElderBrotherInLaw>!$_"
public let CNLabelContactRelationElderCousin = "_$!<ElderCousin>!$_"
public let CNLabelContactRelationElderCousinFathersBrothersDaughter = "_$!<ElderCousinFathersBrothersDaughter>!$_"
public let CNLabelContactRelationElderCousinFathersBrothersSon = "_$!<ElderCousinFathersBrothersSon>!$_"
public let CNLabelContactRelationElderCousinFathersSistersDaughter = "_$!<ElderCousinFathersSistersDaughter>!$_"
public let CNLabelContactRelationElderCousinFathersSistersSon = "_$!<ElderCousinFathersSistersSon>!$_"
public let CNLabelContactRelationElderCousinMothersBrothersDaughter = "_$!<ElderCousinMothersBrothersDaughter>!$_"
public let CNLabelContactRelationElderCousinMothersBrothersSon = "_$!<ElderCousinMothersBrothersSon>!$_"
public let CNLabelContactRelationElderCousinMothersSiblingsDaughterOrFathersSistersDaughter = "_$!<ElderCousinMothersSiblingsDaughterOrFathersSistersDaughter>!$_"
public let CNLabelContactRelationElderCousinMothersSiblingsSonOrFathersSistersSon = "_$!<ElderCousinMothersSiblingsSonOrFathersSistersSon>!$_"
public let CNLabelContactRelationElderCousinMothersSistersDaughter = "_$!<ElderCousinMothersSistersDaughter>!$_"
public let CNLabelContactRelationElderCousinMothersSistersSon = "_$!<ElderCousinMothersSistersSon>!$_"
public let CNLabelContactRelationElderCousinParentsSiblingsDaughter = "_$!<ElderCousinParentsSiblingsDaughter>!$_"
public let CNLabelContactRelationElderCousinParentsSiblingsSon = "_$!<ElderCousinParentsSiblingsSon>!$_"
public let CNLabelContactRelationElderSibling = "_$!<ElderSibling>!$_"
public let CNLabelContactRelationElderSiblingInLaw = "_$!<ElderSiblingInLaw>!$_"
public let CNLabelContactRelationElderSister = "_$!<ElderSister>!$_"
public let CNLabelContactRelationElderSisterInLaw = "_$!<ElderSisterInLaw>!$_"
public let CNLabelContactRelationEldestBrother = "_$!<EldestBrother>!$_"
public let CNLabelContactRelationEldestSister = "_$!<EldestSister>!$_"
public let CNLabelContactRelationFather = "_$!<Father>!$_"
public let CNLabelContactRelationFatherInLaw = "_$!<FatherInLaw>!$_"
public let CNLabelContactRelationFatherInLawHusbandsFather = "_$!<FatherInLawHusbandsFather>!$_"
public let CNLabelContactRelationFatherInLawOrStepfather = "_$!<FatherInLawOrStepfather>!$_"
public let CNLabelContactRelationFatherInLawWifesFather = "_$!<FatherInLawWifesFather>!$_"
public let CNLabelContactRelationFemaleCousin = "_$!<FemaleCousin>!$_"
public let CNLabelContactRelationFemaleFriend = "_$!<FemaleFriend>!$_"
public let CNLabelContactRelationFemalePartner = "_$!<FemalePartner>!$_"
public let CNLabelContactRelationFriend = "_$!<Friend>!$_"
public let CNLabelContactRelationGirlfriend = "_$!<Girlfriend>!$_"
public let CNLabelContactRelationGirlfriendOrBoyfriend = "_$!<GirlfriendOrBoyfriend>!$_"
public let CNLabelContactRelationGrandaunt = "_$!<Grandaunt>!$_"
public let CNLabelContactRelationGrandchild = "_$!<Grandchild>!$_"
public let CNLabelContactRelationGrandchildOrSiblingsChild = "_$!<GrandchildOrSiblingsChild>!$_"
public let CNLabelContactRelationGranddaughter = "_$!<Granddaughter>!$_"
public let CNLabelContactRelationGranddaughterDaughtersDaughter = "_$!<GranddaughterDaughtersDaughter>!$_"
public let CNLabelContactRelationGranddaughterOrNiece = "_$!<GranddaughterOrNiece>!$_"
public let CNLabelContactRelationGranddaughterSonsDaughter = "_$!<GranddaughterSonsDaughter>!$_"
public let CNLabelContactRelationGrandfather = "_$!<Grandfather>!$_"
public let CNLabelContactRelationGrandfatherFathersFather = "_$!<GrandfatherFathersFather>!$_"
public let CNLabelContactRelationGrandfatherMothersFather = "_$!<GrandfatherMothersFather>!$_"
public let CNLabelContactRelationGrandmother = "_$!<Grandmother>!$_"
public let CNLabelContactRelationGrandmotherFathersMother = "_$!<GrandmotherFathersMother>!$_"
public let CNLabelContactRelationGrandmotherMothersMother = "_$!<GrandmotherMothersMother>!$_"
public let CNLabelContactRelationGrandnephew = "_$!<Grandnephew>!$_"
public let CNLabelContactRelationGrandnephewBrothersGrandson = "_$!<GrandnephewBrothersGrandson>!$_"
public let CNLabelContactRelationGrandnephewSistersGrandson = "_$!<GrandnephewSistersGrandson>!$_"
public let CNLabelContactRelationGrandniece = "_$!<Grandniece>!$_"
public let CNLabelContactRelationGrandnieceBrothersGranddaughter = "_$!<GrandnieceBrothersGranddaughter>!$_"
public let CNLabelContactRelationGrandnieceSistersGranddaughter = "_$!<GrandnieceSistersGranddaughter>!$_"
public let CNLabelContactRelationGrandparent = "_$!<Grandparent>!$_"
public let CNLabelContactRelationGrandson = "_$!<Grandson>!$_"
public let CNLabelContactRelationGrandsonDaughtersSon = "_$!<GrandsonDaughtersSon>!$_"
public let CNLabelContactRelationGrandsonOrNephew = "_$!<GrandsonOrNephew>!$_"
public let CNLabelContactRelationGrandsonSonsSon = "_$!<GrandsonSonsSon>!$_"
public let CNLabelContactRelationGranduncle = "_$!<Granduncle>!$_"
public let CNLabelContactRelationGreatGrandchild = "_$!<GreatGrandchild>!$_"
public let CNLabelContactRelationGreatGrandchildOrSiblingsGrandchild = "_$!<GreatGrandchildOrSiblingsGrandchild>!$_"
public let CNLabelContactRelationGreatGranddaughter = "_$!<GreatGranddaughter>!$_"
public let CNLabelContactRelationGreatGrandfather = "_$!<GreatGrandfather>!$_"
public let CNLabelContactRelationGreatGrandmother = "_$!<GreatGrandmother>!$_"
public let CNLabelContactRelationGreatGrandparent = "_$!<GreatGrandparent>!$_"
public let CNLabelContactRelationGreatGrandson = "_$!<GreatGrandson>!$_"
public let CNLabelContactRelationHusband = "_$!<Husband>!$_"
public let CNLabelContactRelationMaleCousin = "_$!<MaleCousin>!$_"
public let CNLabelContactRelationMaleFriend = "_$!<MaleFriend>!$_"
public let CNLabelContactRelationMalePartner = "_$!<MalePartner>!$_"
public let CNLabelContactRelationManager = "_$!<Manager>!$_"
public let CNLabelContactRelationMother = "_$!<Mother>!$_"
public let CNLabelContactRelationMotherInLaw = "_$!<MotherInLaw>!$_"
public let CNLabelContactRelationMotherInLawHusbandsMother = "_$!<MotherInLawHusbandsMother>!$_"
public let CNLabelContactRelationMotherInLawOrStepmother = "_$!<MotherInLawOrStepmother>!$_"
public let CNLabelContactRelationMotherInLawWifesMother = "_$!<MotherInLawWifesMother>!$_"
public let CNLabelContactRelationNephew = "_$!<Nephew>!$_"
public let CNLabelContactRelationNephewBrothersSon = "_$!<NephewBrothersSon>!$_"
public let CNLabelContactRelationNephewBrothersSonOrHusbandsSiblingsSon = "_$!<NephewBrothersSonOrHusbandsSiblingsSon>!$_"
public let CNLabelContactRelationNephewOrCousin = "_$!<NephewOrCousin>!$_"
public let CNLabelContactRelationNephewSistersSon = "_$!<NephewSistersSon>!$_"
public let CNLabelContactRelationNephewSistersSonOrWifesSiblingsSon = "_$!<NephewSistersSonOrWifesSiblingsSon>!$_"
public let CNLabelContactRelationNiece = "_$!<Niece>!$_"
public let CNLabelContactRelationNieceBrothersDaughter = "_$!<NieceBrothersDaughter>!$_"
public let CNLabelContactRelationNieceBrothersDaughterOrHusbandsSiblingsDaughter = "_$!<NieceBrothersDaughterOrHusbandsSiblingsDaughter>!$_"
public let CNLabelContactRelationNieceOrCousin = "_$!<NieceOrCousin>!$_"
public let CNLabelContactRelationNieceSistersDaughter = "_$!<NieceSistersDaughter>!$_"
public let CNLabelContactRelationNieceSistersDaughterOrWifesSiblingsDaughter = "_$!<NieceSistersDaughterOrWifesSiblingsDaughter>!$_"
public let CNLabelContactRelationParent = "_$!<Parent>!$_"
public let CNLabelContactRelationParentInLaw = "_$!<ParentInLaw>!$_"
public let CNLabelContactRelationParentsElderSibling = "_$!<ParentsElderSibling>!$_"
public let CNLabelContactRelationParentsSibling = "_$!<ParentsSibling>!$_"
public let CNLabelContactRelationParentsSiblingFathersElderSibling = "_$!<ParentsSiblingFathersElderSibling>!$_"
public let CNLabelContactRelationParentsSiblingFathersSibling = "_$!<ParentsSiblingFathersSibling>!$_"
public let CNLabelContactRelationParentsSiblingFathersYoungerSibling = "_$!<ParentsSiblingFathersYoungerSibling>!$_"
public let CNLabelContactRelationParentsSiblingMothersElderSibling = "_$!<ParentsSiblingMothersElderSibling>!$_"
public let CNLabelContactRelationParentsSiblingMothersSibling = "_$!<ParentsSiblingMothersSibling>!$_"
public let CNLabelContactRelationParentsSiblingMothersYoungerSibling = "_$!<ParentsSiblingMothersYoungerSibling>!$_"
public let CNLabelContactRelationParentsYoungerSibling = "_$!<ParentsYoungerSibling>!$_"
public let CNLabelContactRelationPartner = "_$!<Partner>!$_"
public let CNLabelContactRelationSibling = "_$!<Sibling>!$_"
public let CNLabelContactRelationSiblingInLaw = "_$!<SiblingInLaw>!$_"
public let CNLabelContactRelationSiblingsChild = "_$!<SiblingsChild>!$_"
public let CNLabelContactRelationSister = "_$!<Sister>!$_"
public let CNLabelContactRelationSisterInLaw = "_$!<SisterInLaw>!$_"
public let CNLabelContactRelationSisterInLawBrothersWife = "_$!<SisterInLawBrothersWife>!$_"
public let CNLabelContactRelationSisterInLawElderBrothersWife = "_$!<SisterInLawElderBrothersWife>!$_"
public let CNLabelContactRelationSisterInLawHusbandsBrothersWife = "_$!<SisterInLawHusbandsBrothersWife>!$_"
public let CNLabelContactRelationSisterInLawHusbandsSister = "_$!<SisterInLawHusbandsSister>!$_"
public let CNLabelContactRelationSisterInLawSpousesSister = "_$!<SisterInLawSpousesSister>!$_"
public let CNLabelContactRelationSisterInLawWifesBrothersWife = "_$!<SisterInLawWifesBrothersWife>!$_"
public let CNLabelContactRelationSisterInLawWifesSister = "_$!<SisterInLawWifesSister>!$_"
public let CNLabelContactRelationSisterInLawYoungerBrothersWife = "_$!<SisterInLawYoungerBrothersWife>!$_"
public let CNLabelContactRelationSon = "_$!<Son>!$_"
public let CNLabelContactRelationSonInLaw = "_$!<SonInLaw>!$_"
public let CNLabelContactRelationSonInLawOrBrotherInLaw = "_$!<SonInLawOrBrotherInLaw>!$_"
public let CNLabelContactRelationSonInLawOrStepson = "_$!<SonInLawOrStepson>!$_"
public let CNLabelContactRelationSpouse = "_$!<Spouse>!$_"
public let CNLabelContactRelationStepbrother = "_$!<Stepbrother>!$_"
public let CNLabelContactRelationStepchild = "_$!<Stepchild>!$_"
public let CNLabelContactRelationStepdaughter = "_$!<Stepdaughter>!$_"
public let CNLabelContactRelationStepfather = "_$!<Stepfather>!$_"
public let CNLabelContactRelationStepmother = "_$!<Stepmother>!$_"
public let CNLabelContactRelationStepparent = "_$!<Stepparent>!$_"
public let CNLabelContactRelationStepsister = "_$!<Stepsister>!$_"
public let CNLabelContactRelationStepson = "_$!<Stepson>!$_"
public let CNLabelContactRelationTeacher = "_$!<Teacher>!$_"
public let CNLabelContactRelationUncle = "_$!<Uncle>!$_"
public let CNLabelContactRelationUncleFathersBrother = "_$!<UncleFathersBrother>!$_"
public let CNLabelContactRelationUncleFathersElderBrother = "_$!<UncleFathersElderBrother>!$_"
public let CNLabelContactRelationUncleFathersElderSistersHusband = "_$!<UncleFathersElderSistersHusband>!$_"
public let CNLabelContactRelationUncleFathersSistersHusband = "_$!<UncleFathersSistersHusband>!$_"
public let CNLabelContactRelationUncleFathersYoungerBrother = "_$!<UncleFathersYoungerBrother>!$_"
public let CNLabelContactRelationUncleFathersYoungerSistersHusband = "_$!<UncleFathersYoungerSistersHusband>!$_"
public let CNLabelContactRelationUncleMothersBrother = "_$!<UncleMothersBrother>!$_"
public let CNLabelContactRelationUncleMothersElderBrother = "_$!<UncleMothersElderBrother>!$_"
public let CNLabelContactRelationUncleMothersSistersHusband = "_$!<UncleMothersSistersHusband>!$_"
public let CNLabelContactRelationUncleMothersYoungerBrother = "_$!<UncleMothersYoungerBrother>!$_"
public let CNLabelContactRelationUncleParentsBrother = "_$!<UncleParentsBrother>!$_"
public let CNLabelContactRelationUncleParentsElderBrother = "_$!<UncleParentsElderBrother>!$_"
public let CNLabelContactRelationUncleParentsYoungerBrother = "_$!<UncleParentsYoungerBrother>!$_"
public let CNLabelContactRelationWife = "_$!<Wife>!$_"
public let CNLabelContactRelationYoungerBrother = "_$!<YoungerBrother>!$_"
public let CNLabelContactRelationYoungerBrotherInLaw = "_$!<YoungerBrotherInLaw>!$_"
public let CNLabelContactRelationYoungerCousin = "_$!<YoungerCousin>!$_"
public let CNLabelContactRelationYoungerCousinFathersBrothersDaughter = "_$!<YoungerCousinFathersBrothersDaughter>!$_"
public let CNLabelContactRelationYoungerCousinFathersBrothersSon = "_$!<YoungerCousinFathersBrothersSon>!$_"
public let CNLabelContactRelationYoungerCousinFathersSistersDaughter = "_$!<YoungerCousinFathersSistersDaughter>!$_"
public let CNLabelContactRelationYoungerCousinFathersSistersSon = "_$!<YoungerCousinFathersSistersSon>!$_"
public let CNLabelContactRelationYoungerCousinMothersBrothersDaughter = "_$!<YoungerCousinMothersBrothersDaughter>!$_"
public let CNLabelContactRelationYoungerCousinMothersBrothersSon = "_$!<YoungerCousinMothersBrothersSon>!$_"
public let CNLabelContactRelationYoungerCousinMothersSiblingsDaughterOrFathersSistersDaughter = "_$!<YoungerCousinMothersSiblingsDaughterOrFathersSistersDaughter>!$_"
public let CNLabelContactRelationYoungerCousinMothersSiblingsSonOrFathersSistersSon = "_$!<YoungerCousinMothersSiblingsSonOrFathersSistersSon>!$_"
public let CNLabelContactRelationYoungerCousinMothersSistersDaughter = "_$!<YoungerCousinMothersSistersDaughter>!$_"
public let CNLabelContactRelationYoungerCousinMothersSistersSon = "_$!<YoungerCousinMothersSistersSon>!$_"
public let CNLabelContactRelationYoungerCousinParentsSiblingsDaughter = "_$!<YoungerCousinParentsSiblingsDaughter>!$_"
public let CNLabelContactRelationYoungerCousinParentsSiblingsSon = "_$!<YoungerCousinParentsSiblingsSon>!$_"
public let CNLabelContactRelationYoungerSibling = "_$!<YoungerSibling>!$_"
public let CNLabelContactRelationYoungerSiblingInLaw = "_$!<YoungerSiblingInLaw>!$_"
public let CNLabelContactRelationYoungerSister = "_$!<YoungerSister>!$_"
public let CNLabelContactRelationYoungerSisterInLaw = "_$!<YoungerSisterInLaw>!$_"
public let CNLabelContactRelationYoungestBrother = "_$!<YoungestBrother>!$_"
public let CNLabelContactRelationYoungestSister = "_$!<YoungestSister>!$_"
public let CNLabelDateAnniversary = "_$!<Anniversary>!$_"
public let CNLabelEmailiCloud = "iCloud"
public let CNLabelHome = "_$!<Home>!$_"
public let CNLabelOther = "_$!<Other>!$_"
public let CNLabelPhoneNumberAppleWatch = "Apple Watch"
public let CNLabelPhoneNumberHomeFax = "_$!<HomeFAX>!$_"
public let CNLabelPhoneNumberMain = "_$!<Main>!$_"
public let CNLabelPhoneNumberMobile = "_$!<Mobile>!$_"
public let CNLabelPhoneNumberOtherFax = "_$!<OtherFAX>!$_"
public let CNLabelPhoneNumberPager = "_$!<Pager>!$_"
public let CNLabelPhoneNumberWorkFax = "_$!<WorkFAX>!$_"
public let CNLabelPhoneNumberiPhone = "iPhone"
public let CNLabelSchool = "_$!<School>!$_"
public let CNLabelURLAddressHomePage = "_$!<HomePage>!$_"
public let CNLabelWork = "_$!<Work>!$_"
public let CNPostalAddressCityKey = "city"
public let CNPostalAddressCountryKey = "country"
public let CNPostalAddressISOCountryCodeKey = "ISOCountryCode"
public let CNPostalAddressLocalizedPropertyNameAttribute = "CNPostalAddressLocalizedPropertyNameAttribute"
public let CNPostalAddressPostalCodeKey = "postalCode"
public let CNPostalAddressPropertyAttribute = "CNPostalAddressPropertyAttribute"
public let CNPostalAddressStateKey = "state"
public let CNPostalAddressStreetKey = "street"
public let CNPostalAddressSubAdministrativeAreaKey = "subAdministrativeArea"
public let CNPostalAddressSubLocalityKey = "subLocality"
public let CNSocialProfileServiceFacebook = "Facebook"
public let CNSocialProfileServiceFlickr = "Flickr"
public let CNSocialProfileServiceGameCenter = "GameCenter"
public let CNSocialProfileServiceKey = "service"
public let CNSocialProfileServiceLinkedIn = "LinkedIn"
public let CNSocialProfileServiceMySpace = "MySpace"
public let CNSocialProfileServiceSinaWeibo = "SinaWeibo"
public let CNSocialProfileServiceTencentWeibo = "TencentWeibo"
public let CNSocialProfileServiceTwitter = "Twitter"
public let CNSocialProfileServiceYelp = "Yelp"
public let CNSocialProfileURLStringKey = "urlString"
public let CNSocialProfileUserIdentifierKey = "userIdentifier"
public let CNSocialProfileUsernameKey = "username"

public func CNAllPublicStringConstants() -> [String] {
    [
        CNContactBirthdayKey,
        CNContactDatesKey,
        CNContactDepartmentNameKey,
        CNContactEmailAddressesKey,
        CNContactFamilyNameKey,
        CNContactGivenNameKey,
        CNContactIdentifierKey,
        CNContactImageDataAvailableKey,
        CNContactImageDataKey,
        CNContactInstantMessageAddressesKey,
        CNContactJobTitleKey,
        CNContactMiddleNameKey,
        CNContactNamePrefixKey,
        CNContactNameSuffixKey,
        CNContactNicknameKey,
        CNContactNonGregorianBirthdayKey,
        CNContactNoteKey,
        CNContactOrganizationNameKey,
        CNContactPhoneNumbersKey,
        CNContactPhoneticFamilyNameKey,
        CNContactPhoneticGivenNameKey,
        CNContactPhoneticMiddleNameKey,
        CNContactPhoneticOrganizationNameKey,
        CNContactPostalAddressesKey,
        CNContactPreviousFamilyNameKey,
        CNContactPropertyAttribute,
        CNContactPropertyNotFetchedExceptionName,
        CNContactRelationsKey,
        CNContactSocialProfilesKey,
        CNContactThumbnailImageDataKey,
        CNContactTypeKey,
        CNContactUrlAddressesKey,
        CNContainerIdentifierKey,
        CNContainerNameKey,
        CNContainerTypeKey,
        CNErrorDomain,
        CNErrorUserInfoAffectedRecordIdentifiersKey,
        CNErrorUserInfoAffectedRecordsKey,
        CNErrorUserInfoKeyPathsKey,
        CNErrorUserInfoValidationErrorsKey,
        CNGroupIdentifierKey,
        CNGroupNameKey,
        CNInstantMessageAddressServiceKey,
        CNInstantMessageAddressUsernameKey,
        CNInstantMessageServiceAIM,
        CNInstantMessageServiceFacebook,
        CNInstantMessageServiceGaduGadu,
        CNInstantMessageServiceGoogleTalk,
        CNInstantMessageServiceICQ,
        CNInstantMessageServiceJabber,
        CNInstantMessageServiceMSN,
        CNInstantMessageServiceQQ,
        CNInstantMessageServiceSkype,
        CNInstantMessageServiceYahoo,
        CNLabelContactRelationAssistant,
        CNLabelContactRelationAunt,
        CNLabelContactRelationAuntFathersBrothersWife,
        CNLabelContactRelationAuntFathersElderBrothersWife,
        CNLabelContactRelationAuntFathersElderSister,
        CNLabelContactRelationAuntFathersSister,
        CNLabelContactRelationAuntFathersYoungerBrothersWife,
        CNLabelContactRelationAuntFathersYoungerSister,
        CNLabelContactRelationAuntMothersBrothersWife,
        CNLabelContactRelationAuntMothersElderSister,
        CNLabelContactRelationAuntMothersSister,
        CNLabelContactRelationAuntMothersYoungerSister,
        CNLabelContactRelationAuntParentsElderSister,
        CNLabelContactRelationAuntParentsSister,
        CNLabelContactRelationAuntParentsYoungerSister,
        CNLabelContactRelationBoyfriend,
        CNLabelContactRelationBrother,
        CNLabelContactRelationBrotherInLaw,
        CNLabelContactRelationBrotherInLawElderSistersHusband,
        CNLabelContactRelationBrotherInLawHusbandsBrother,
        CNLabelContactRelationBrotherInLawHusbandsSistersHusband,
        CNLabelContactRelationBrotherInLawSistersHusband,
        CNLabelContactRelationBrotherInLawSpousesBrother,
        CNLabelContactRelationBrotherInLawWifesBrother,
        CNLabelContactRelationBrotherInLawWifesSistersHusband,
        CNLabelContactRelationBrotherInLawYoungerSistersHusband,
        CNLabelContactRelationChild,
        CNLabelContactRelationChildInLaw,
        CNLabelContactRelationCoBrotherInLaw,
        CNLabelContactRelationCoFatherInLaw,
        CNLabelContactRelationCoMotherInLaw,
        CNLabelContactRelationCoParentInLaw,
        CNLabelContactRelationCoSiblingInLaw,
        CNLabelContactRelationCoSisterInLaw,
        CNLabelContactRelationColleague,
        CNLabelContactRelationCousin,
        CNLabelContactRelationCousinFathersBrothersDaughter,
        CNLabelContactRelationCousinFathersBrothersSon,
        CNLabelContactRelationCousinFathersSistersDaughter,
        CNLabelContactRelationCousinFathersSistersSon,
        CNLabelContactRelationCousinGrandparentsSiblingsChild,
        CNLabelContactRelationCousinGrandparentsSiblingsDaughter,
        CNLabelContactRelationCousinGrandparentsSiblingsSon,
        CNLabelContactRelationCousinMothersBrothersDaughter,
        CNLabelContactRelationCousinMothersBrothersSon,
        CNLabelContactRelationCousinMothersSistersDaughter,
        CNLabelContactRelationCousinMothersSistersSon,
        CNLabelContactRelationCousinOrSiblingsChild,
        CNLabelContactRelationCousinParentsSiblingsChild,
        CNLabelContactRelationCousinParentsSiblingsDaughter,
        CNLabelContactRelationCousinParentsSiblingsSon,
        CNLabelContactRelationDaughter,
        CNLabelContactRelationDaughterInLaw,
        CNLabelContactRelationDaughterInLawOrSisterInLaw,
        CNLabelContactRelationDaughterInLawOrStepdaughter,
        CNLabelContactRelationElderBrother,
        CNLabelContactRelationElderBrotherInLaw,
        CNLabelContactRelationElderCousin,
        CNLabelContactRelationElderCousinFathersBrothersDaughter,
        CNLabelContactRelationElderCousinFathersBrothersSon,
        CNLabelContactRelationElderCousinFathersSistersDaughter,
        CNLabelContactRelationElderCousinFathersSistersSon,
        CNLabelContactRelationElderCousinMothersBrothersDaughter,
        CNLabelContactRelationElderCousinMothersBrothersSon,
        CNLabelContactRelationElderCousinMothersSiblingsDaughterOrFathersSistersDaughter,
        CNLabelContactRelationElderCousinMothersSiblingsSonOrFathersSistersSon,
        CNLabelContactRelationElderCousinMothersSistersDaughter,
        CNLabelContactRelationElderCousinMothersSistersSon,
        CNLabelContactRelationElderCousinParentsSiblingsDaughter,
        CNLabelContactRelationElderCousinParentsSiblingsSon,
        CNLabelContactRelationElderSibling,
        CNLabelContactRelationElderSiblingInLaw,
        CNLabelContactRelationElderSister,
        CNLabelContactRelationElderSisterInLaw,
        CNLabelContactRelationEldestBrother,
        CNLabelContactRelationEldestSister,
        CNLabelContactRelationFather,
        CNLabelContactRelationFatherInLaw,
        CNLabelContactRelationFatherInLawHusbandsFather,
        CNLabelContactRelationFatherInLawOrStepfather,
        CNLabelContactRelationFatherInLawWifesFather,
        CNLabelContactRelationFemaleCousin,
        CNLabelContactRelationFemaleFriend,
        CNLabelContactRelationFemalePartner,
        CNLabelContactRelationFriend,
        CNLabelContactRelationGirlfriend,
        CNLabelContactRelationGirlfriendOrBoyfriend,
        CNLabelContactRelationGrandaunt,
        CNLabelContactRelationGrandchild,
        CNLabelContactRelationGrandchildOrSiblingsChild,
        CNLabelContactRelationGranddaughter,
        CNLabelContactRelationGranddaughterDaughtersDaughter,
        CNLabelContactRelationGranddaughterOrNiece,
        CNLabelContactRelationGranddaughterSonsDaughter,
        CNLabelContactRelationGrandfather,
        CNLabelContactRelationGrandfatherFathersFather,
        CNLabelContactRelationGrandfatherMothersFather,
        CNLabelContactRelationGrandmother,
        CNLabelContactRelationGrandmotherFathersMother,
        CNLabelContactRelationGrandmotherMothersMother,
        CNLabelContactRelationGrandnephew,
        CNLabelContactRelationGrandnephewBrothersGrandson,
        CNLabelContactRelationGrandnephewSistersGrandson,
        CNLabelContactRelationGrandniece,
        CNLabelContactRelationGrandnieceBrothersGranddaughter,
        CNLabelContactRelationGrandnieceSistersGranddaughter,
        CNLabelContactRelationGrandparent,
        CNLabelContactRelationGrandson,
        CNLabelContactRelationGrandsonDaughtersSon,
        CNLabelContactRelationGrandsonOrNephew,
        CNLabelContactRelationGrandsonSonsSon,
        CNLabelContactRelationGranduncle,
        CNLabelContactRelationGreatGrandchild,
        CNLabelContactRelationGreatGrandchildOrSiblingsGrandchild,
        CNLabelContactRelationGreatGranddaughter,
        CNLabelContactRelationGreatGrandfather,
        CNLabelContactRelationGreatGrandmother,
        CNLabelContactRelationGreatGrandparent,
        CNLabelContactRelationGreatGrandson,
        CNLabelContactRelationHusband,
        CNLabelContactRelationMaleCousin,
        CNLabelContactRelationMaleFriend,
        CNLabelContactRelationMalePartner,
        CNLabelContactRelationManager,
        CNLabelContactRelationMother,
        CNLabelContactRelationMotherInLaw,
        CNLabelContactRelationMotherInLawHusbandsMother,
        CNLabelContactRelationMotherInLawOrStepmother,
        CNLabelContactRelationMotherInLawWifesMother,
        CNLabelContactRelationNephew,
        CNLabelContactRelationNephewBrothersSon,
        CNLabelContactRelationNephewBrothersSonOrHusbandsSiblingsSon,
        CNLabelContactRelationNephewOrCousin,
        CNLabelContactRelationNephewSistersSon,
        CNLabelContactRelationNephewSistersSonOrWifesSiblingsSon,
        CNLabelContactRelationNiece,
        CNLabelContactRelationNieceBrothersDaughter,
        CNLabelContactRelationNieceBrothersDaughterOrHusbandsSiblingsDaughter,
        CNLabelContactRelationNieceOrCousin,
        CNLabelContactRelationNieceSistersDaughter,
        CNLabelContactRelationNieceSistersDaughterOrWifesSiblingsDaughter,
        CNLabelContactRelationParent,
        CNLabelContactRelationParentInLaw,
        CNLabelContactRelationParentsElderSibling,
        CNLabelContactRelationParentsSibling,
        CNLabelContactRelationParentsSiblingFathersElderSibling,
        CNLabelContactRelationParentsSiblingFathersSibling,
        CNLabelContactRelationParentsSiblingFathersYoungerSibling,
        CNLabelContactRelationParentsSiblingMothersElderSibling,
        CNLabelContactRelationParentsSiblingMothersSibling,
        CNLabelContactRelationParentsSiblingMothersYoungerSibling,
        CNLabelContactRelationParentsYoungerSibling,
        CNLabelContactRelationPartner,
        CNLabelContactRelationSibling,
        CNLabelContactRelationSiblingInLaw,
        CNLabelContactRelationSiblingsChild,
        CNLabelContactRelationSister,
        CNLabelContactRelationSisterInLaw,
        CNLabelContactRelationSisterInLawBrothersWife,
        CNLabelContactRelationSisterInLawElderBrothersWife,
        CNLabelContactRelationSisterInLawHusbandsBrothersWife,
        CNLabelContactRelationSisterInLawHusbandsSister,
        CNLabelContactRelationSisterInLawSpousesSister,
        CNLabelContactRelationSisterInLawWifesBrothersWife,
        CNLabelContactRelationSisterInLawWifesSister,
        CNLabelContactRelationSisterInLawYoungerBrothersWife,
        CNLabelContactRelationSon,
        CNLabelContactRelationSonInLaw,
        CNLabelContactRelationSonInLawOrBrotherInLaw,
        CNLabelContactRelationSonInLawOrStepson,
        CNLabelContactRelationSpouse,
        CNLabelContactRelationStepbrother,
        CNLabelContactRelationStepchild,
        CNLabelContactRelationStepdaughter,
        CNLabelContactRelationStepfather,
        CNLabelContactRelationStepmother,
        CNLabelContactRelationStepparent,
        CNLabelContactRelationStepsister,
        CNLabelContactRelationStepson,
        CNLabelContactRelationTeacher,
        CNLabelContactRelationUncle,
        CNLabelContactRelationUncleFathersBrother,
        CNLabelContactRelationUncleFathersElderBrother,
        CNLabelContactRelationUncleFathersElderSistersHusband,
        CNLabelContactRelationUncleFathersSistersHusband,
        CNLabelContactRelationUncleFathersYoungerBrother,
        CNLabelContactRelationUncleFathersYoungerSistersHusband,
        CNLabelContactRelationUncleMothersBrother,
        CNLabelContactRelationUncleMothersElderBrother,
        CNLabelContactRelationUncleMothersSistersHusband,
        CNLabelContactRelationUncleMothersYoungerBrother,
        CNLabelContactRelationUncleParentsBrother,
        CNLabelContactRelationUncleParentsElderBrother,
        CNLabelContactRelationUncleParentsYoungerBrother,
        CNLabelContactRelationWife,
        CNLabelContactRelationYoungerBrother,
        CNLabelContactRelationYoungerBrotherInLaw,
        CNLabelContactRelationYoungerCousin,
        CNLabelContactRelationYoungerCousinFathersBrothersDaughter,
        CNLabelContactRelationYoungerCousinFathersBrothersSon,
        CNLabelContactRelationYoungerCousinFathersSistersDaughter,
        CNLabelContactRelationYoungerCousinFathersSistersSon,
        CNLabelContactRelationYoungerCousinMothersBrothersDaughter,
        CNLabelContactRelationYoungerCousinMothersBrothersSon,
        CNLabelContactRelationYoungerCousinMothersSiblingsDaughterOrFathersSistersDaughter,
        CNLabelContactRelationYoungerCousinMothersSiblingsSonOrFathersSistersSon,
        CNLabelContactRelationYoungerCousinMothersSistersDaughter,
        CNLabelContactRelationYoungerCousinMothersSistersSon,
        CNLabelContactRelationYoungerCousinParentsSiblingsDaughter,
        CNLabelContactRelationYoungerCousinParentsSiblingsSon,
        CNLabelContactRelationYoungerSibling,
        CNLabelContactRelationYoungerSiblingInLaw,
        CNLabelContactRelationYoungerSister,
        CNLabelContactRelationYoungerSisterInLaw,
        CNLabelContactRelationYoungestBrother,
        CNLabelContactRelationYoungestSister,
        CNLabelDateAnniversary,
        CNLabelEmailiCloud,
        CNLabelHome,
        CNLabelOther,
        CNLabelPhoneNumberAppleWatch,
        CNLabelPhoneNumberHomeFax,
        CNLabelPhoneNumberMain,
        CNLabelPhoneNumberMobile,
        CNLabelPhoneNumberOtherFax,
        CNLabelPhoneNumberPager,
        CNLabelPhoneNumberWorkFax,
        CNLabelPhoneNumberiPhone,
        CNLabelSchool,
        CNLabelURLAddressHomePage,
        CNLabelWork,
        CNPostalAddressCityKey,
        CNPostalAddressCountryKey,
        CNPostalAddressISOCountryCodeKey,
        CNPostalAddressLocalizedPropertyNameAttribute,
        CNPostalAddressPostalCodeKey,
        CNPostalAddressPropertyAttribute,
        CNPostalAddressStateKey,
        CNPostalAddressStreetKey,
        CNPostalAddressSubAdministrativeAreaKey,
        CNPostalAddressSubLocalityKey,
        CNSocialProfileServiceFacebook,
        CNSocialProfileServiceFlickr,
        CNSocialProfileServiceGameCenter,
        CNSocialProfileServiceKey,
        CNSocialProfileServiceLinkedIn,
        CNSocialProfileServiceMySpace,
        CNSocialProfileServiceSinaWeibo,
        CNSocialProfileServiceTencentWeibo,
        CNSocialProfileServiceTwitter,
        CNSocialProfileServiceYelp,
        CNSocialProfileURLStringKey,
        CNSocialProfileUserIdentifierKey,
        CNSocialProfileUsernameKey,
    ]
}
