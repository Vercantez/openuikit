// Generated Intents enumerations from the sealed public surface.
// Raw values follow pinned dotnet/macios bindings when present; otherwise
// sequential Int overlay order from the graph case list.

public enum INAccountType: Int, Hashable, Sendable {
    case checking = 1
    case credit = 2
    case debit = 3
    case investment = 4
    case mortgage = 5
    case prepaid = 6
    case saving = 7
    case unknown = 0
}

public enum INActivateCarSignalIntentResponseCode: Int, Hashable, Sendable {
    case failure = 4
    case failureRequiringAppLaunch = 5
    case inProgress = 2
    case ready = 1
    case success = 3
    case unspecified = 0
}

public enum INAddMediaIntentResponseCode: Int, Hashable, Sendable {
    case failure = 5
    case failureRequiringAppLaunch = 6
    case handleInApp = 4
    case inProgress = 2
    case ready = 1
    case success = 3
    case unspecified = 0
}

public enum INAddMediaMediaDestinationUnsupportedReason: Int, Hashable, Sendable {
    case playlistNameNotFound = 1
    case playlistNotEditable = 2
}

public enum INAddMediaMediaItemUnsupportedReason: Int, Hashable, Sendable {
    case cellularDataSettings = 5
    case explicitContentSettings = 4
    case loginRequired = 1
    case regionRestriction = 8
    case restrictedContent = 6
    case serviceUnavailable = 7
    case subscriptionRequired = 2
    case unsupportedMediaType = 3
}

public enum INAddTasksIntentResponseCode: Int, Hashable, Sendable {
    case failure = 4
    case failureRequiringAppLaunch = 5
    case inProgress = 2
    case ready = 1
    case success = 3
    case unspecified = 0
}

public enum INAddTasksTargetTaskListConfirmationReason: Int, Hashable, Sendable {
    case listShouldBeCreated = 1
}

public enum INAddTasksTemporalEventTriggerUnsupportedReason: Int, Hashable, Sendable {
    case invalidRecurrence = 2
    case timeInPast = 1
}

public enum INAmountType: Int, Hashable, Sendable {
    case amountDue = 2
    case currentBalance = 3
    case maximumTransferAmount = 4
    case minimumDue = 1
    case minimumTransferAmount = 5
    case statementBalance = 6
    case unknown = 0
}

public enum INAnswerCallIntentResponseCode: Int, Hashable, Sendable {
    case continueInApp = 2
    case failure = 5
    case failureRequiringAppLaunch = 6
    case inProgress = 3
    case ready = 1
    case success = 4
    case unspecified = 0
}

public enum INAppendToNoteIntentResponseCode: Int, Hashable, Sendable {
    case failure = 4
    case failureCannotUpdatePasswordProtectedNote = 6
    case failureRequiringAppLaunch = 5
    case inProgress = 2
    case ready = 1
    case success = 3
    case unspecified = 0
}

public enum INBalanceType: Int, Hashable, Sendable {
    case miles = 3
    case money = 1
    case points = 2
    case unknown = 0
}

public enum INBillType: Int, Hashable, Sendable {
    case autoInsurance = 1
    case cable = 2
    case carLease = 3
    case carLoan = 4
    case creditCard = 5
    case electricity = 6
    case garbageAndRecycling = 8
    case gas = 7
    case healthInsurance = 9
    case homeInsurance = 10
    case internet = 11
    case lifeInsurance = 12
    case mortgage = 13
    case musicStreaming = 14
    case phone = 15
    case rent = 16
    case sewer = 17
    case studentLoan = 18
    case trafficTicket = 19
    case tuition = 20
    case unknown = 0
    case utilities = 21
    case water = 22
}

public enum INBookRestaurantReservationIntentCode: Int, Hashable, Sendable {
    case denied = 1
    case failure = 2
    case failureRequiringAppLaunch = 3
    case failureRequiringAppLaunchMustVerifyCredentials = 4
    case failureRequiringAppLaunchServiceTemporarilyUnavailable = 5
    case success = 0
}

public enum INCallAudioRoute: Int, Hashable, Sendable {
    case bluetoothAudioRoute = 2
    case speakerphoneAudioRoute = 1
    case unknown = 0
}

public enum INCallCapability: Int, Hashable, Sendable {
    case audioCall = 1
    case unknown = 0
    case videoCall = 2
}

public enum INCallDestinationType: Int, Hashable, Sendable {
    case callBack = 5
    case emergency = 2
    case normal = 1
    case redial = 4
    case unknown = 0
    case voicemail = 3
}

public enum INCallRecordType: Int, Hashable, Sendable {
    case inProgress = 7
    case latest = 4
    case missed = 2
    case onHold = 8
    case outgoing = 1
    case received = 3
    case ringing = 6
    case unknown = 0
    case voicemail = 5
}

public enum INCancelRideIntentResponseCode: Int, Hashable, Sendable {
    case failure = 3
    case ready = 1
    case success = 2
    case unspecified = 0
}

public enum INCancelWorkoutIntentResponseCode: Int, Hashable, Sendable {
    case continueInApp = 2
    case failure = 3
    case failureNoMatchingWorkout = 5
    case failureRequiringAppLaunch = 4
    case handleInApp = 6
    case ready = 1
    case success = 7
    case unspecified = 0
}

public enum INCarAirCirculationMode: Int, Hashable, Sendable {
    case freshAir = 1
    case recirculateAir = 2
    case unknown = 0
}

public enum INCarAudioSource: Int, Hashable, Sendable {
    case sourceAUX = 0
    case sourceBluetooth = 1
    case sourceCarPlay = 2
    case sourceHardDrive = 3
    case sourceMemoryCard = 4
    case sourceOpticalDrive = 5
    case sourceRadio = 6
    case sourceUSB = 7
    case sourceUnknown = 8
    case sourceiPod = 9
}

public enum INCarDefroster: Int, Hashable, Sendable {
    case all = 3
    case front = 1
    case rear = 2
    case unknown = 0
}

public enum INCarSeat: Int, Hashable, Sendable {
    case all = 12
    case driver = 1
    case front = 5
    case frontLeft = 3
    case frontRight = 4
    case passenger = 2
    case rear = 8
    case rearLeft = 6
    case rearRight = 7
    case thirdRow = 11
    case thirdRowLeft = 9
    case thirdRowRight = 10
    case unknown = 0
}

public enum INConditionalOperator: Int, Hashable, Sendable {
    case all = 0
    case any = 1
    case none = 2
}

public enum INCreateNoteIntentResponseCode: Int, Hashable, Sendable {
    case failure = 4
    case failureRequiringAppLaunch = 5
    case inProgress = 2
    case ready = 1
    case success = 3
    case unspecified = 0
}

public enum INCreateTaskListIntentResponseCode: Int, Hashable, Sendable {
    case failure = 4
    case failureRequiringAppLaunch = 5
    case inProgress = 2
    case ready = 1
    case success = 3
    case unspecified = 0
}

public enum INDateSearchType: Int, Hashable, Sendable {
    case byCreatedDate = 3
    case byDueDate = 1
    case byModifiedDate = 2
    case unknown = 0
}

public enum INDeleteTasksIntentResponseCode: Int, Hashable, Sendable {
    case failure = 4
    case failureRequiringAppLaunch = 5
    case inProgress = 2
    case ready = 1
    case success = 3
    case unspecified = 0
}

public enum INDeleteTasksTaskListUnsupportedReason: Int, Hashable, Sendable {
    case noTaskListFound = 1
}

public enum INDeleteTasksTaskUnsupportedReason: Int, Hashable, Sendable {
    case noTasksFound = 0
    case noTasksInApp = 1
}

public enum INEditMessageIntentResponseCode: Int, Hashable, Sendable {
    case failure = 4
    case failureMessageNotFound = 6
    case failureMessageServiceNotAvailable = 10
    case failureMessageTypeUnsupported = 8
    case failurePastEditTimeLimit = 7
    case failureRequiringAppLaunch = 5
    case failureRequiringInAppAuthentication = 11
    case failureUnsupportedOnService = 9
    case inProgress = 2
    case ready = 1
    case success = 3
    case unspecified = 0
}

public enum INEndWorkoutIntentResponseCode: Int, Hashable, Sendable {
    case continueInApp = 2
    case failure = 3
    case failureNoMatchingWorkout = 5
    case failureRequiringAppLaunch = 4
    case handleInApp = 6
    case ready = 1
    case success = 7
    case unspecified = 0
}

public enum INGetAvailableRestaurantReservationBookingDefaultsIntentResponseCode: Int, Hashable, Sendable {
    case failure = 1
    case success = 0
    case unspecified = 2
}

public enum INGetAvailableRestaurantReservationBookingsIntentCode: Int, Hashable, Sendable {
    case failure = 1
    case failureRequestUnsatisfiable = 2
    case failureRequestUnspecified = 3
    case success = 0
}

public enum INGetCarLockStatusIntentResponseCode: Int, Hashable, Sendable {
    case failure = 4
    case failureRequiringAppLaunch = 5
    case inProgress = 2
    case ready = 1
    case success = 3
    case unspecified = 0
}

public enum INGetCarPowerLevelStatusIntentResponseCode: Int, Hashable, Sendable {
    case failure = 4
    case failureRequiringAppLaunch = 5
    case inProgress = 2
    case ready = 1
    case success = 3
    case unspecified = 0
}

public enum INGetReservationDetailsIntentResponseCode: Int, Hashable, Sendable {
    case failure = 4
    case failureRequiringAppLaunch = 5
    case inProgress = 2
    case ready = 1
    case success = 3
    case unspecified = 0
}

public enum INGetRestaurantGuestIntentResponseCode: Int, Hashable, Sendable {
    case failure = 1
    case success = 0
}

public enum INGetRideStatusIntentResponseCode: Int, Hashable, Sendable {
    case failure = 4
    case failureRequiringAppLaunch = 5
    case failureRequiringAppLaunchMustVerifyCredentials = 6
    case failureRequiringAppLaunchServiceTemporarilyUnavailable = 7
    case inProgress = 2
    case ready = 1
    case success = 3
    case unspecified = 0
}

public enum INGetUserCurrentRestaurantReservationBookingsIntentResponseCode: Int, Hashable, Sendable {
    case failure = 1
    case failureRequestUnsatisfiable = 2
    case success = 0
    case unspecified = 3
}

public enum INGetVisualCodeIntentResponseCode: Int, Hashable, Sendable {
    case continueInApp = 2
    case failure = 5
    case failureAppConfigurationRequired = 7
    case failureRequiringAppLaunch = 6
    case inProgress = 3
    case ready = 1
    case success = 4
    case unspecified = 0
}

public enum INHangUpCallIntentResponseCode: Int, Hashable, Sendable {
    case failure = 4
    case failureNoCallToHangUp = 6
    case failureRequiringAppLaunch = 5
    case inProgress = 2
    case ready = 1
    case success = 3
    case unspecified = 0
}

public enum INIntentHandlingStatus: Int, Hashable, Sendable {
    case deferredToApplication = 5
    case failure = 4
    case inProgress = 2
    case ready = 1
    case success = 3
    case unspecified = 0
    case userConfirmationRequired = 6
}

public enum INListCarsIntentResponseCode: Int, Hashable, Sendable {
    case failure = 4
    case failureRequiringAppLaunch = 5
    case inProgress = 2
    case ready = 1
    case success = 3
    case unspecified = 0
}

public enum INListRideOptionsIntentResponseCode: Int, Hashable, Sendable {
    case failure = 4
    case failurePreviousRideNeedsFeedback = 10
    case failureRequiringAppLaunch = 5
    case failureRequiringAppLaunchMustVerifyCredentials = 6
    case failureRequiringAppLaunchNoServiceInArea = 7
    case failureRequiringAppLaunchPreviousRideNeedsCompletion = 9
    case failureRequiringAppLaunchServiceTemporarilyUnavailable = 8
    case inProgress = 2
    case ready = 1
    case success = 3
    case unspecified = 0
}

public enum INLocationSearchType: Int, Hashable, Sendable {
    case byLocationTrigger = 1
    case unknown = 0
}

public enum INMediaAffinityType: Int, Hashable, Sendable {
    case dislike = 2
    case like = 1
    case unknown = 0
}

public enum INMediaDestinationType: Int, Hashable, Sendable {
    case library = 1
    case playlist = 2
    case unknown = 0
}

public enum INMediaReference: Int, Hashable, Sendable {
    case currentlyPlaying = 1
    case my = 2
    case unknown = 0
}

public enum INMediaSortOrder: Int, Hashable, Sendable {
    case best = 3
    case newest = 1
    case oldest = 2
    case popular = 5
    case recommended = 8
    case trending = 7
    case unknown = 0
    case unpopular = 6
    case worst = 4
}

public enum INMessageAttribute: Int, Hashable, Sendable {
    case flagged = 3
    case played = 5
    case read = 1
    case unflagged = 4
    case unknown = 0
    case unread = 2
}

public enum INMessageReactionType: Int, Hashable, Sendable {
    case emoji = 1
    case generic = 2
    case unknown = 0
}

public enum INMessageType: Int, Hashable, Sendable {
    case activitySnippet = 23
    case animoji = 22
    case audio = 2
    case digitalTouch = 3
    case file = 24
    case handwriting = 4
    case link = 25
    case mediaAddressCard = 14
    case mediaAnimatedImage = 27
    case mediaAudio = 18
    case mediaCalendar = 12
    case mediaImage = 15
    case mediaLocation = 13
    case mediaPass = 17
    case mediaVideo = 16
    case paymentNote = 21
    case paymentRequest = 20
    case paymentSent = 19
    case reaction = 26
    case sticker = 5
    case tapbackDisliked = 7
    case tapbackEmphasized = 8
    case tapbackLaughed = 11
    case tapbackLiked = 6
    case tapbackLoved = 9
    case tapbackQuestioned = 10
    case text = 1
    case thirdPartyAttachment = 28
    case unspecified = 0
}

public enum INNoteContentType: Int, Hashable, Sendable {
    case image = 2
    case text = 1
    case unknown = 0
}

public enum INNotebookItemType: Int, Hashable, Sendable {
    case note = 1
    case task = 3
    case taskList = 2
    case unknown = 0
}

public enum INOutgoingMessageType: Int, Hashable, Sendable {
    case outgoingMessageAudio = 1
    case outgoingMessageText = 2
    case unknown = 0
}

public enum INPauseWorkoutIntentResponseCode: Int, Hashable, Sendable {
    case continueInApp = 2
    case failure = 3
    case failureNoMatchingWorkout = 5
    case failureRequiringAppLaunch = 4
    case handleInApp = 6
    case ready = 1
    case success = 7
    case unspecified = 0
}

public enum INPayBillIntentResponseCode: Int, Hashable, Sendable {
    case failure = 4
    case failureCredentialsUnverified = 6
    case failureInsufficientFunds = 7
    case failureRequiringAppLaunch = 5
    case inProgress = 2
    case ready = 1
    case success = 3
    case unspecified = 0
}

public enum INPaymentMethodType: Int, Hashable, Sendable {
    case applePay = 8
    case brokerage = 3
    case checking = 1
    case credit = 5
    case debit = 4
    case prepaid = 6
    case savings = 2
    case store = 7
    case unknown = 0
}

public enum INPaymentStatus: Int, Hashable, Sendable {
    case canceled = 3
    case completed = 2
    case failed = 4
    case pending = 1
    case unknown = 0
    case unpaid = 5
}

public enum INPlayMediaIntentResponseCode: Int, Hashable, Sendable {
    case continueInApp = 2
    case failure = 6
    case failureMaxStreamLimitReached = 11
    case failureNoUnplayedContent = 9
    case failureRequiringAppLaunch = 7
    case failureRestrictedContent = 10
    case failureUnknownMediaType = 8
    case handleInApp = 5
    case inProgress = 3
    case ready = 1
    case success = 4
    case unspecified = 0
}

public enum INPlayMediaMediaItemUnsupportedReason: Int, Hashable, Sendable {
    case cellularDataSettings = 5
    case explicitContentSettings = 4
    case loginRequired = 1
    case regionRestriction = 8
    case restrictedContent = 6
    case serviceUnavailable = 7
    case subscriptionRequired = 2
    case unsupportedMediaType = 3
}

public enum INPlayMediaPlaybackSpeedUnsupportedReason: Int, Hashable, Sendable {
    case aboveMaximum = 2
    case belowMinimum = 1
}

public enum INPlaybackQueueLocation: Int, Hashable, Sendable {
    case later = 3
    case next = 2
    case now = 1
    case unknown = 0
}

public enum INPlaybackRepeatMode: Int, Hashable, Sendable {
    case all = 2
    case none = 1
    case one = 3
    case unknown = 0
}

public enum INRadioType: Int, Hashable, Sendable {
    case AM = 1
    case DAB = 5
    case FM = 2
    case HD = 3
    case satellite = 4
    case unknown = 0
}

public enum INRecurrenceFrequency: Int, Hashable, Sendable {
    case daily = 3
    case hourly = 2
    case minute = 1
    case monthly = 5
    case unknown = 0
    case weekly = 4
    case yearly = 6
}

public enum INRelativeReference: Int, Hashable, Sendable {
    case next = 1
    case previous = 2
    case unknown = 0
}

public enum INRelativeSetting: Int, Hashable, Sendable {
    case higher = 3
    case highest = 4
    case lower = 2
    case lowest = 1
    case unknown = 0
}

public enum INRelevantShortcutRole: Int, Hashable, Sendable {
    case action = 0
    case information = 1
}

public enum INRequestPaymentCurrencyAmountUnsupportedReason: Int, Hashable, Sendable {
    case paymentsAmountAboveMaximum = 0
    case paymentsAmountBelowMinimum = 1
    case paymentsCurrencyUnsupported = 2
}

public enum INRequestPaymentIntentResponseCode: Int, Hashable, Sendable {
    case failure = 4
    case failureCredentialsUnverified = 6
    case failureNoBankAccount = 10
    case failureNotEligible = 11
    case failurePaymentsAmountAboveMaximum = 8
    case failurePaymentsAmountBelowMinimum = 7
    case failurePaymentsCurrencyUnsupported = 9
    case failureRequiringAppLaunch = 5
    case failureTermsAndConditionsAcceptanceRequired = 12
    case inProgress = 2
    case ready = 1
    case success = 3
    case unspecified = 0
}

public enum INRequestPaymentPayerUnsupportedReason: Int, Hashable, Sendable {
    case credentialsUnverified = 1
    case noAccount = 2
    case noValidHandle = 3
}

public enum INRequestRideIntentResponseCode: Int, Hashable, Sendable {
    case failure = 4
    case failureRequiringAppLaunch = 5
    case failureRequiringAppLaunchMustVerifyCredentials = 6
    case failureRequiringAppLaunchNoServiceInArea = 7
    case failureRequiringAppLaunchPreviousRideNeedsCompletion = 9
    case failureRequiringAppLaunchRideScheduledTooFar = 10
    case failureRequiringAppLaunchServiceTemporarilyUnavailable = 8
    case inProgress = 2
    case ready = 1
    case success = 3
    case unspecified = 0
}

public enum INReservationActionType: Int, Hashable, Sendable {
    case checkIn = 1
    case unknown = 0
}

public enum INReservationStatus: Int, Hashable, Sendable {
    case canceled = 1
    case confirmed = 4
    case hold = 3
    case pending = 2
    case unknown = 0
}

public enum INRestaurantReservationUserBookingStatus: Int, Hashable, Sendable {
    case confirmed = 1
    case denied = 2
    case pending = 0
}

public enum INResumeWorkoutIntentResponseCode: Int, Hashable, Sendable {
    case continueInApp = 2
    case failure = 3
    case failureNoMatchingWorkout = 5
    case failureRequiringAppLaunch = 4
    case handleInApp = 6
    case ready = 1
    case success = 7
    case unspecified = 0
}

public enum INRidePhase: Int, Hashable, Sendable {
    case approachingPickup = 5
    case completed = 4
    case confirmed = 2
    case ongoing = 3
    case pickup = 6
    case received = 1
    case unknown = 0
}

public enum INSaveProfileInCarIntentResponseCode: Int, Hashable, Sendable {
    case failure = 4
    case failureRequiringAppLaunch = 5
    case inProgress = 2
    case ready = 1
    case success = 3
    case unspecified = 0
}

public enum INSearchCallHistoryIntentResponseCode: Int, Hashable, Sendable {
    case continueInApp = 2
    case failure = 3
    case failureAppConfigurationRequired = 5
    case failureRequiringAppLaunch = 4
    case inProgress = 6
    case ready = 1
    case success = 7
    case unspecified = 0
}

public enum INSearchForAccountsIntentResponseCode: Int, Hashable, Sendable {
    case failure = 4
    case failureAccountNotFound = 7
    case failureCredentialsUnverified = 6
    case failureNotEligible = 9
    case failureRequiringAppLaunch = 5
    case failureTermsAndConditionsAcceptanceRequired = 8
    case inProgress = 2
    case ready = 1
    case success = 3
    case unspecified = 0
}

public enum INSearchForBillsIntentResponseCode: Int, Hashable, Sendable {
    case failure = 4
    case failureBillNotFound = 7
    case failureCredentialsUnverified = 6
    case failureRequiringAppLaunch = 5
    case inProgress = 2
    case ready = 1
    case success = 3
    case unspecified = 0
}

public enum INSearchForMediaIntentResponseCode: Int, Hashable, Sendable {
    case continueInApp = 2
    case failure = 5
    case failureRequiringAppLaunch = 6
    case inProgress = 3
    case ready = 1
    case success = 4
    case unspecified = 0
}

public enum INSearchForMediaMediaItemUnsupportedReason: Int, Hashable, Sendable {
    case cellularDataSettings = 5
    case explicitContentSettings = 4
    case loginRequired = 1
    case regionRestriction = 8
    case restrictedContent = 6
    case serviceUnavailable = 7
    case subscriptionRequired = 2
    case unsupportedMediaType = 3
}

public enum INSearchForMessagesIntentResponseCode: Int, Hashable, Sendable {
    case failure = 4
    case failureMessageServiceNotAvailable = 6
    case failureMessageTooManyResults = 7
    case failureRequiringAppLaunch = 5
    case failureRequiringInAppAuthentication = 8
    case inProgress = 2
    case ready = 1
    case success = 3
    case unspecified = 0
}

public enum INSearchForNotebookItemsIntentResponseCode: Int, Hashable, Sendable {
    case failure = 4
    case failureRequiringAppLaunch = 5
    case inProgress = 2
    case ready = 1
    case success = 3
    case unspecified = 0
}

public enum INSearchForPhotosIntentResponseCode: Int, Hashable, Sendable {
    case continueInApp = 2
    case failure = 3
    case failureAppConfigurationRequired = 5
    case failureRequiringAppLaunch = 4
    case ready = 1
    case unspecified = 0
}

public enum INSendMessageIntentResponseCode: Int, Hashable, Sendable {
    case failure = 4
    case failureMessageServiceNotAvailable = 6
    case failureRequiringAppLaunch = 5
    case failureRequiringInAppAuthentication = 7
    case inProgress = 2
    case ready = 1
    case success = 3
    case unspecified = 0
}

public enum INSendMessageRecipientUnsupportedReason: Int, Hashable, Sendable {
    case messagingServiceNotEnabledForRecipient = 3
    case noAccount = 1
    case noHandleForLabel = 6
    case noValidHandle = 4
    case offline = 2
    case requestedHandleInvalid = 5
    case requiringInAppAuthentication = 7
}

public enum INSendPaymentCurrencyAmountUnsupportedReason: Int, Hashable, Sendable {
    case paymentsAmountAboveMaximum = 0
    case paymentsAmountBelowMinimum = 1
    case paymentsCurrencyUnsupported = 2
}

public enum INSendPaymentIntentResponseCode: Int, Hashable, Sendable {
    case failure = 4
    case failureCredentialsUnverified = 6
    case failureInsufficientFunds = 10
    case failureNoBankAccount = 11
    case failureNotEligible = 12
    case failurePaymentsAmountAboveMaximum = 8
    case failurePaymentsAmountBelowMinimum = 7
    case failurePaymentsCurrencyUnsupported = 9
    case failureRequiringAppLaunch = 5
    case failureTermsAndConditionsAcceptanceRequired = 13
    case inProgress = 2
    case ready = 1
    case success = 3
    case unspecified = 0
}

public enum INSendPaymentPayeeUnsupportedReason: Int, Hashable, Sendable {
    case credentialsUnverified = 1
    case insufficientFunds = 2
    case noAccount = 3
    case noValidHandle = 4
}

public enum INSendRideFeedbackIntentResponseCode: Int, Hashable, Sendable {
    case failure = 3
    case ready = 1
    case success = 2
    case unspecified = 0
}

public enum INSetAudioSourceInCarIntentResponseCode: Int, Hashable, Sendable {
    case failure = 4
    case failureRequiringAppLaunch = 5
    case inProgress = 2
    case ready = 1
    case success = 3
    case unspecified = 0
}

public enum INSetCarLockStatusIntentResponseCode: Int, Hashable, Sendable {
    case failure = 4
    case failureRequiringAppLaunch = 5
    case inProgress = 2
    case ready = 1
    case success = 3
    case unspecified = 0
}

public enum INSetClimateSettingsInCarIntentResponseCode: Int, Hashable, Sendable {
    case failure = 4
    case failureRequiringAppLaunch = 5
    case inProgress = 2
    case ready = 1
    case success = 3
    case unspecified = 0
}

public enum INSetDefrosterSettingsInCarIntentResponseCode: Int, Hashable, Sendable {
    case failure = 4
    case failureRequiringAppLaunch = 5
    case inProgress = 2
    case ready = 1
    case success = 3
    case unspecified = 0
}

public enum INSetMessageAttributeIntentResponseCode: Int, Hashable, Sendable {
    case failure = 4
    case failureMessageAttributeNotSet = 7
    case failureMessageNotFound = 6
    case failureRequiringAppLaunch = 5
    case inProgress = 2
    case ready = 1
    case success = 3
    case unspecified = 0
}

public enum INSetProfileInCarIntentResponseCode: Int, Hashable, Sendable {
    case failure = 4
    case failureRequiringAppLaunch = 5
    case inProgress = 2
    case ready = 1
    case success = 3
    case unspecified = 0
}

public enum INSetRadioStationIntentResponseCode: Int, Hashable, Sendable {
    case failure = 4
    case failureNotSubscribed = 6
    case failureRequiringAppLaunch = 5
    case inProgress = 2
    case ready = 1
    case success = 3
    case unspecified = 0
}

public enum INSetSeatSettingsInCarIntentResponseCode: Int, Hashable, Sendable {
    case failure = 4
    case failureRequiringAppLaunch = 5
    case inProgress = 2
    case ready = 1
    case success = 3
    case unspecified = 0
}

public enum INSetTaskAttributeIntentResponseCode: Int, Hashable, Sendable {
    case failure = 4
    case failureRequiringAppLaunch = 5
    case inProgress = 2
    case ready = 1
    case success = 3
    case unspecified = 0
}

public enum INSetTaskAttributeTemporalEventTriggerUnsupportedReason: Int, Hashable, Sendable {
    case invalidRecurrence = 2
    case timeInPast = 1
}

public enum INShareFocusStatusIntentResponseCode: Int, Hashable, Sendable {
    case failure = 4
    case failureRequiringAppLaunch = 5
    case inProgress = 2
    case ready = 1
    case success = 3
    case unspecified = 0
}

public enum INSiriAuthorizationStatus: Int, Hashable, Sendable {
    case authorized = 3
    case denied = 2
    case notDetermined = 0
    case restricted = 1
}

public enum INSnoozeTasksIntentResponseCode: Int, Hashable, Sendable {
    case failure = 4
    case failureRequiringAppLaunch = 5
    case inProgress = 2
    case ready = 1
    case success = 3
    case unspecified = 0
}

public enum INSnoozeTasksTaskUnsupportedReason: Int, Hashable, Sendable {
    case noTasksFound = 1
}

public enum INSortType: Int, Hashable, Sendable {
    case asIs = 1
    case byDate = 2
    case unknown = 0
}

public enum INSpatialEvent: Int, Hashable, Sendable {
    case arrive = 1
    case depart = 2
    case unknown = 0
}

public enum INStartAudioCallIntentResponseCode: Int, Hashable, Sendable {
    case continueInApp = 2
    case failure = 3
    case failureAppConfigurationRequired = 5
    case failureCallingServiceNotAvailable = 6
    case failureContactNotSupportedByApp = 7
    case failureNoValidNumber = 8
    case failureRequiringAppLaunch = 4
    case ready = 1
    case unspecified = 0
}

public enum INStartCallCallCapabilityUnsupportedReason: Int, Hashable, Sendable {
    case cameraNotAccessible = 3
    case microphoneNotAccessible = 2
    case videoCallUnsupported = 1
}

public enum INStartCallCallRecordToCallBackUnsupportedReason: Int, Hashable, Sendable {
    case noMatchingCall = 1
}

public enum INStartCallContactUnsupportedReason: Int, Hashable, Sendable {
    case invalidHandle = 4
    case multipleContactsUnsupported = 2
    case noCallHistoryForRedial = 6
    case noContactFound = 1
    case noHandleForLabel = 3
    case noUsableHandleForRedial = 7
    case requiringInAppAuthentication = 8
    case unsupportedMmiUssd = 5
}

public enum INStartCallIntentResponseCode: Int, Hashable, Sendable {
    case continueInApp = 2
    case failure = 4
    case failureAirplaneModeEnabled = 8
    case failureAppConfigurationRequired = 10
    case failureCallInProgress = 11
    case failureCallingServiceNotAvailable = 6
    case failureContactNotSupportedByApp = 7
    case failureRequiringAppLaunch = 5
    case failureRequiringInAppAuthentication = 12
    case failureUnableToHandOff = 9
    case ready = 1
    case unspecified = 0
    case userConfirmationRequired = 3
}

public enum INStartPhotoPlaybackIntentResponseCode: Int, Hashable, Sendable {
    case continueInApp = 2
    case failure = 3
    case failureAppConfigurationRequired = 5
    case failureRequiringAppLaunch = 4
    case ready = 1
    case unspecified = 0
}

public enum INStartVideoCallIntentResponseCode: Int, Hashable, Sendable {
    case continueInApp = 2
    case failure = 3
    case failureAppConfigurationRequired = 5
    case failureCallingServiceNotAvailable = 6
    case failureContactNotSupportedByApp = 7
    case failureInvalidNumber = 8
    case failureRequiringAppLaunch = 4
    case ready = 1
    case unspecified = 0
}

public enum INStartWorkoutIntentResponseCode: Int, Hashable, Sendable {
    case continueInApp = 2
    case failure = 3
    case failureNoMatchingWorkout = 6
    case failureOngoingWorkout = 5
    case failureRequiringAppLaunch = 4
    case handleInApp = 7
    case ready = 1
    case success = 8
    case unspecified = 0
}

public enum INTaskPriority: Int, Hashable, Sendable {
    case flagged = 2
    case notFlagged = 1
    case unknown = 0
}

public enum INTaskStatus: Int, Hashable, Sendable {
    case completed = 2
    case notCompleted = 1
    case unknown = 0
}

public enum INTaskType: Int, Hashable, Sendable {
    case completable = 2
    case notCompletable = 1
    case unknown = 0
}

public enum INTicketedEventCategory: Int, Hashable, Sendable {
    case movie = 1
    case unknown = 0
}

public enum INTransferMoneyIntentResponseCode: Int, Hashable, Sendable {
    case failure = 4
    case failureCredentialsUnverified = 6
    case failureInsufficientFunds = 7
    case failureRequiringAppLaunch = 5
    case inProgress = 2
    case ready = 1
    case success = 3
    case unspecified = 0
}

public enum INUnsendMessagesIntentResponseCode: Int, Hashable, Sendable {
    case failure = 4
    case failureMessageNotFound = 6
    case failureMessageServiceNotAvailable = 10
    case failureMessageTypeUnsupported = 8
    case failurePastUnsendTimeLimit = 7
    case failureRequiringAppLaunch = 5
    case failureRequiringInAppAuthentication = 11
    case failureUnsupportedOnService = 9
    case inProgress = 2
    case ready = 1
    case success = 3
    case unspecified = 0
}

public enum INUpcomingMediaPredictionMode: Int, Hashable, Sendable {
    case `default` = 0
    case onlyPredictSuggestedIntents = 1
}

public enum INUpdateMediaAffinityIntentResponseCode: Int, Hashable, Sendable {
    case failure = 4
    case failureRequiringAppLaunch = 5
    case inProgress = 2
    case ready = 1
    case success = 3
    case unspecified = 0
}

public enum INUpdateMediaAffinityMediaItemUnsupportedReason: Int, Hashable, Sendable {
    case cellularDataSettings = 5
    case explicitContentSettings = 4
    case loginRequired = 1
    case regionRestriction = 8
    case restrictedContent = 6
    case serviceUnavailable = 7
    case subscriptionRequired = 2
    case unsupportedMediaType = 3
}

public enum INVisualCodeType: Int, Hashable, Sendable {
    case bus = 5
    case contact = 1
    case requestPayment = 2
    case sendPayment = 3
    case subway = 6
    case transit = 4
    case unknown = 0
}

public enum INVocabularyStringType: Int, Hashable, Sendable {
    case carName = 301
    case carProfileName = 300
    case contactGroupName = 2
    case contactName = 1
    case mediaAudiobookAuthorName = 703
    case mediaAudiobookTitle = 702
    case mediaMusicArtistName = 701
    case mediaPlaylistTitle = 700
    case mediaShowTitle = 704
    case notebookItemGroupName = 501
    case notebookItemTitle = 500
    case paymentsAccountNickname = 401
    case paymentsOrganizationName = 400
    case photoAlbumName = 101
    case photoTag = 100
    case workoutActivityName = 200
}

public enum INWorkoutGoalUnitType: Int, Hashable, Sendable {
    case foot = 3
    case hour = 8
    case inch = 1
    case joule = 9
    case kiloCalorie = 10
    case meter = 2
    case mile = 4
    case minute = 7
    case second = 6
    case unknown = 0
    case yard = 5
}

public enum INWorkoutLocationType: Int, Hashable, Sendable {
    case indoor = 2
    case outdoor = 1
    case unknown = 0
}
