package com.sparrowinvest.app.ui.invest

import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.CalendarMonth
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.CloudUpload
import androidx.compose.material.icons.filled.Image
import androidx.compose.material.icons.filled.TrendingDown
import androidx.compose.material.icons.filled.TrendingUp
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DatePicker
import androidx.compose.material3.DatePickerDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.rememberDatePickerState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.rememberAsyncImagePainter
import com.sparrowinvest.app.ui.theme.CardBackgroundDark
import com.sparrowinvest.app.ui.theme.CardBackgroundLight
import com.sparrowinvest.app.ui.theme.CornerRadius
import com.sparrowinvest.app.ui.theme.Error
import com.sparrowinvest.app.ui.theme.GlassBorderEndDark
import com.sparrowinvest.app.ui.theme.GlassBorderEndLight
import com.sparrowinvest.app.ui.theme.GlassBorderMidDark
import com.sparrowinvest.app.ui.theme.GlassBorderMidLight
import com.sparrowinvest.app.ui.theme.GlassBorderStartDark
import com.sparrowinvest.app.ui.theme.GlassBorderStartLight
import com.sparrowinvest.app.ui.theme.LocalIsDarkTheme
import com.sparrowinvest.app.ui.theme.Primary
import com.sparrowinvest.app.ui.theme.Secondary
import com.sparrowinvest.app.ui.theme.ShadowColor
import com.sparrowinvest.app.ui.theme.Spacing
import com.sparrowinvest.app.ui.theme.Success
import com.sparrowinvest.app.ui.theme.TertiaryFillDark
import com.sparrowinvest.app.ui.theme.TertiaryFillLight
import kotlinx.coroutines.delay
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ManualInvestmentScreen(
    onBackClick: () -> Unit,
    onSave: () -> Unit
) {
    val isDark = LocalIsDarkTheme.current
    var selectedTab by remember { mutableIntStateOf(0) }

    // Manual entry fields
    var fundName by remember { mutableStateOf("") }
    var units by remember { mutableStateOf("") }
    var investedAmount by remember { mutableStateOf("") }
    var currentValue by remember { mutableStateOf("") }
    var purchaseDate by remember { mutableStateOf(Date()) }
    var showDatePicker by remember { mutableStateOf(false) }

    // Screenshot upload state
    var selectedImageUri by remember { mutableStateOf<Uri?>(null) }
    var isProcessing by remember { mutableStateOf(false) }

    // Photo picker launcher
    val photoPickerLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.PickVisualMedia()
    ) { uri: Uri? ->
        selectedImageUri = uri
        if (uri != null) {
            isProcessing = true
        }
    }

    // Simulate processing delay
    LaunchedEffect(isProcessing) {
        if (isProcessing) {
            delay(2000)
            isProcessing = false
        }
    }

    // Validation
    val isValidEntry = if (selectedTab == 0) {
        fundName.isNotBlank() && investedAmount.isNotBlank()
    } else {
        selectedImageUri != null && !isProcessing
    }

    // Date picker dialog
    if (showDatePicker) {
        val datePickerState = rememberDatePickerState(
            initialSelectedDateMillis = purchaseDate.time
        )
        DatePickerDialog(
            onDismissRequest = { showDatePicker = false },
            confirmButton = {
                TextButton(
                    onClick = {
                        datePickerState.selectedDateMillis?.let {
                            purchaseDate = Date(it)
                        }
                        showDatePicker = false
                    }
                ) {
                    Text("OK")
                }
            },
            dismissButton = {
                TextButton(onClick = { showDatePicker = false }) {
                    Text("Cancel")
                }
            }
        ) {
            DatePicker(state = datePickerState)
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Add Investment") },
                navigationIcon = {
                    IconButton(onClick = onBackClick) {
                        Icon(
                            Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = "Back"
                        )
                    }
                },
                actions = {
                    TextButton(
                        onClick = {
                            // TODO: Save to local storage
                            onSave()
                        },
                        enabled = isValidEntry
                    ) {
                        Text(
                            text = "Save",
                            fontWeight = FontWeight.SemiBold,
                            color = if (isValidEntry) Primary else MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.background
                )
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            // Tab Selector
            TabSelector(
                selectedTab = selectedTab,
                onTabSelected = { selectedTab = it },
                isDark = isDark,
                modifier = Modifier.padding(Spacing.medium)
            )

            if (selectedTab == 0) {
                ManualEntryForm(
                    fundName = fundName,
                    onFundNameChange = { fundName = it },
                    units = units,
                    onUnitsChange = { units = it },
                    investedAmount = investedAmount,
                    onInvestedAmountChange = { investedAmount = it },
                    currentValue = currentValue,
                    onCurrentValueChange = { currentValue = it },
                    purchaseDate = purchaseDate,
                    onDateClick = { showDatePicker = true },
                    isDark = isDark
                )
            } else {
                ScreenshotUploadView(
                    selectedImageUri = selectedImageUri,
                    isProcessing = isProcessing,
                    isDark = isDark,
                    onPickPhoto = {
                        photoPickerLauncher.launch(
                            PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly)
                        )
                    }
                )
            }
        }
    }
}

// ---- Tab Selector ----

@Composable
private fun TabSelector(
    selectedTab: Int,
    onTabSelected: (Int) -> Unit,
    isDark: Boolean,
    modifier: Modifier = Modifier
) {
    val tabs = listOf("Manual Entry", "Upload Screenshot")
    val capsuleShape = RoundedCornerShape(50)
    val containerBackground = if (isDark) CardBackgroundDark else CardBackgroundLight
    val borderBrush = glassBorderBrush(isDark)

    Box(
        modifier = modifier
            .fillMaxWidth()
            .then(
                if (!isDark) Modifier.shadow(8.dp, capsuleShape, spotColor = ShadowColor, ambientColor = ShadowColor)
                else Modifier
            )
            .clip(capsuleShape)
            .background(containerBackground)
            .border(1.dp, borderBrush, capsuleShape)
            .padding(4.dp)
    ) {
        Row(modifier = Modifier.fillMaxWidth()) {
            tabs.forEachIndexed { index, title ->
                val isSelected = selectedTab == index
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .clip(RoundedCornerShape(50))
                        .background(
                            if (isSelected) {
                                Brush.horizontalGradient(listOf(Primary, Secondary))
                            } else {
                                Brush.horizontalGradient(listOf(Color.Transparent, Color.Transparent))
                            }
                        )
                        .clickable { onTabSelected(index) }
                        .padding(vertical = 10.dp),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = title,
                        style = MaterialTheme.typography.bodySmall,
                        fontWeight = FontWeight.Medium,
                        color = if (isSelected) Color.White else MaterialTheme.colorScheme.onSurface
                    )
                }
            }
        }
    }
}

// ---- Manual Entry Form ----

@Composable
private fun ManualEntryForm(
    fundName: String,
    onFundNameChange: (String) -> Unit,
    units: String,
    onUnitsChange: (String) -> Unit,
    investedAmount: String,
    onInvestedAmountChange: (String) -> Unit,
    currentValue: String,
    onCurrentValueChange: (String) -> Unit,
    purchaseDate: Date,
    onDateClick: () -> Unit,
    isDark: Boolean
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(Spacing.medium),
        verticalArrangement = Arrangement.spacedBy(Spacing.large)
    ) {
        // Fund Details Section
        FormSection(
            title = "FUND DETAILS",
            isDark = isDark
        ) {
            PortfolioFormField(
                label = "Fund Name",
                value = fundName,
                onValueChange = onFundNameChange,
                placeholder = "e.g., Parag Parikh Flexi Cap",
                isDark = isDark
            )
            Spacer(modifier = Modifier.height(Spacing.medium))
            PortfolioFormField(
                label = "Units",
                value = units,
                onValueChange = onUnitsChange,
                placeholder = "e.g., 125.50",
                keyboardType = KeyboardType.Decimal,
                isDark = isDark
            )
        }

        // Investment Section
        FormSection(
            title = "INVESTMENT",
            isDark = isDark
        ) {
            PortfolioFormField(
                label = "Invested Amount",
                value = investedAmount,
                onValueChange = onInvestedAmountChange,
                placeholder = "₹",
                keyboardType = KeyboardType.Number,
                isDark = isDark
            )
            Spacer(modifier = Modifier.height(Spacing.medium))
            PortfolioFormField(
                label = "Current Value",
                value = currentValue,
                onValueChange = onCurrentValueChange,
                placeholder = "₹",
                keyboardType = KeyboardType.Number,
                isDark = isDark
            )
            Spacer(modifier = Modifier.height(Spacing.medium))

            // Purchase Date
            Column {
                Text(
                    text = "Purchase Date",
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(modifier = Modifier.height(Spacing.small))
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(52.dp)
                        .clip(RoundedCornerShape(CornerRadius.medium))
                        .background(if (isDark) TertiaryFillDark else TertiaryFillLight)
                        .border(
                            width = 1.dp,
                            color = Color.Transparent,
                            shape = RoundedCornerShape(CornerRadius.medium)
                        )
                        .clickable(onClick = onDateClick)
                        .padding(horizontal = Spacing.medium),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    val dateFormat = SimpleDateFormat("dd MMM yyyy", Locale.getDefault())
                    Text(
                        text = dateFormat.format(purchaseDate),
                        style = MaterialTheme.typography.bodyLarge,
                        color = MaterialTheme.colorScheme.onSurface,
                        modifier = Modifier.weight(1f)
                    )
                    Icon(
                        imageVector = Icons.Default.CalendarMonth,
                        contentDescription = "Select date",
                        tint = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.size(20.dp)
                    )
                }
            }
        }

        // Return Preview
        val invested = investedAmount.toDoubleOrNull()
        val current = currentValue.toDoubleOrNull()
        if (invested != null && current != null && invested > 0) {
            ReturnPreview(
                invested = invested,
                current = current,
                isDark = isDark
            )
        }

        Spacer(modifier = Modifier.height(Spacing.large))
    }
}

@Composable
private fun ReturnPreview(
    invested: Double,
    current: Double,
    isDark: Boolean
) {
    val returnAmount = current - invested
    val returnPercentage = ((current - invested) / invested) * 100
    val isPositive = returnAmount >= 0
    val returnColor = if (isPositive) Success else Error

    Column(verticalArrangement = Arrangement.spacedBy(Spacing.compact)) {
        // Section header
        Text(
            text = "RETURN PREVIEW",
            style = MaterialTheme.typography.labelSmall,
            color = Primary,
            fontWeight = FontWeight.Medium,
            letterSpacing = 1.sp
        )

        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(CornerRadius.large))
                .background(returnColor.copy(alpha = if (isDark) 0.15f else 0.1f))
                .padding(Spacing.medium),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = "Total Return",
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(modifier = Modifier.height(4.dp))
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    val sign = if (isPositive) "+" else "-"
                    Text(
                        text = "${sign}₹${String.format(Locale.US, "%.0f", kotlin.math.abs(returnAmount))}",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.SemiBold,
                        color = returnColor
                    )
                    Text(
                        text = "(${if (isPositive) "+" else ""}${String.format(Locale.US, "%.1f", returnPercentage)}%)",
                        style = MaterialTheme.typography.bodyMedium,
                        fontWeight = FontWeight.Medium,
                        color = returnColor
                    )
                }
            }

            Icon(
                imageVector = if (isPositive) Icons.Default.TrendingUp else Icons.Default.TrendingDown,
                contentDescription = null,
                tint = returnColor,
                modifier = Modifier.size(32.dp)
            )
        }
    }
}

// ---- Form Section Wrapper ----

@Composable
private fun FormSection(
    title: String,
    isDark: Boolean,
    content: @Composable () -> Unit
) {
    val shape = RoundedCornerShape(CornerRadius.large)
    val backgroundColor = if (isDark) CardBackgroundDark else CardBackgroundLight
    val borderBrush = glassBorderBrush(isDark)

    Column(verticalArrangement = Arrangement.spacedBy(Spacing.compact)) {
        Text(
            text = title,
            style = MaterialTheme.typography.labelSmall,
            color = Primary,
            fontWeight = FontWeight.Medium,
            letterSpacing = 1.sp
        )

        Column(
            modifier = Modifier
                .fillMaxWidth()
                .then(
                    if (!isDark) Modifier.shadow(12.dp, shape, spotColor = ShadowColor, ambientColor = ShadowColor)
                    else Modifier
                )
                .clip(shape)
                .background(backgroundColor)
                .border(1.dp, borderBrush, shape)
                .padding(Spacing.medium)
        ) {
            content()
        }
    }
}

// ---- Portfolio Form Field ----

@Composable
fun PortfolioFormField(
    label: String,
    value: String,
    onValueChange: (String) -> Unit,
    placeholder: String,
    keyboardType: KeyboardType = KeyboardType.Text,
    isDark: Boolean = LocalIsDarkTheme.current
) {
    val backgroundColor = if (isDark) TertiaryFillDark else TertiaryFillLight

    Column {
        Text(
            text = label,
            style = MaterialTheme.typography.labelMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )

        Spacer(modifier = Modifier.height(Spacing.small))

        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(52.dp)
                .clip(RoundedCornerShape(CornerRadius.medium))
                .background(backgroundColor)
                .border(
                    width = if (isDark) 0.5.dp else 0.dp,
                    color = if (isDark) Color.White.copy(alpha = 0.08f) else Color.Transparent,
                    shape = RoundedCornerShape(CornerRadius.medium)
                )
                .padding(horizontal = 14.dp),
            contentAlignment = Alignment.CenterStart
        ) {
            BasicTextField(
                value = value,
                onValueChange = onValueChange,
                modifier = Modifier.fillMaxWidth(),
                textStyle = MaterialTheme.typography.bodyLarge.copy(
                    color = MaterialTheme.colorScheme.onSurface
                ),
                keyboardOptions = KeyboardOptions(keyboardType = keyboardType),
                singleLine = true,
                cursorBrush = SolidColor(Primary),
                decorationBox = { innerTextField ->
                    Box {
                        if (value.isEmpty()) {
                            Text(
                                text = placeholder,
                                style = MaterialTheme.typography.bodyLarge,
                                color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.6f)
                            )
                        }
                        innerTextField()
                    }
                }
            )
        }
    }
}

// ---- Screenshot Upload View ----

@Composable
private fun ScreenshotUploadView(
    selectedImageUri: Uri?,
    isProcessing: Boolean,
    isDark: Boolean,
    onPickPhoto: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(Spacing.medium),
        verticalArrangement = Arrangement.spacedBy(Spacing.large)
    ) {
        if (selectedImageUri != null) {
            // Image Preview Section
            ImagePreviewSection(
                imageUri = selectedImageUri,
                isProcessing = isProcessing,
                isDark = isDark,
                onPickPhoto = onPickPhoto
            )
        } else {
            // Upload Prompt
            UploadPromptSection(
                isDark = isDark,
                onPickPhoto = onPickPhoto
            )
        }
    }
}

@Composable
private fun ImagePreviewSection(
    imageUri: Uri,
    isProcessing: Boolean,
    isDark: Boolean,
    onPickPhoto: () -> Unit
) {
    Column(
        modifier = Modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Image preview
        Image(
            painter = rememberAsyncImagePainter(imageUri),
            contentDescription = "Portfolio screenshot",
            modifier = Modifier
                .fillMaxWidth()
                .height(300.dp)
                .clip(RoundedCornerShape(CornerRadius.large)),
            contentScale = ContentScale.Fit
        )

        Spacer(modifier = Modifier.height(Spacing.medium))

        if (isProcessing) {
            // Processing state
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.Center,
                modifier = Modifier.padding(Spacing.medium)
            ) {
                CircularProgressIndicator(
                    modifier = Modifier.size(20.dp),
                    strokeWidth = 2.dp,
                    color = Primary
                )
                Spacer(modifier = Modifier.width(Spacing.compact))
                Text(
                    text = "Processing screenshot...",
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        } else {
            // Success state
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                modifier = Modifier.padding(Spacing.medium)
            ) {
                Icon(
                    imageVector = Icons.Default.CheckCircle,
                    contentDescription = null,
                    tint = Success,
                    modifier = Modifier.size(24.dp)
                )
                Spacer(modifier = Modifier.height(Spacing.small))
                Text(
                    text = "Screenshot uploaded successfully",
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.Medium,
                    color = MaterialTheme.colorScheme.onSurface
                )
                Text(
                    text = "We'll extract your portfolio details automatically.",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    textAlign = TextAlign.Center
                )
            }
        }

        // Change photo button
        TextButton(onClick = onPickPhoto) {
            Icon(
                imageVector = Icons.Default.Image,
                contentDescription = null,
                modifier = Modifier.size(16.dp),
                tint = Primary
            )
            Spacer(modifier = Modifier.width(Spacing.small))
            Text(
                text = "Choose Different Photo",
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.Medium,
                color = Primary
            )
        }
    }
}

@Composable
private fun UploadPromptSection(
    isDark: Boolean,
    onPickPhoto: () -> Unit
) {
    Column(
        modifier = Modifier.fillMaxWidth(),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Spacer(modifier = Modifier.height(40.dp))

        // Large icon circle
        Box(
            modifier = Modifier
                .size(100.dp)
                .clip(CircleShape)
                .background(Primary.copy(alpha = if (isDark) 0.15f else 0.1f)),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = Icons.Default.CloudUpload,
                contentDescription = null,
                tint = Primary,
                modifier = Modifier.size(40.dp)
            )
        }

        Spacer(modifier = Modifier.height(Spacing.medium))

        Text(
            text = "Upload Portfolio Screenshot",
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.SemiBold,
            color = MaterialTheme.colorScheme.onSurface
        )

        Spacer(modifier = Modifier.height(Spacing.small))

        Text(
            text = "Take a screenshot from your broker app showing your mutual fund holdings",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(horizontal = Spacing.medium)
        )

        Spacer(modifier = Modifier.height(Spacing.large))

        // Choose Photo Button (gradient)
        Button(
            onClick = onPickPhoto,
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = Spacing.large)
                .height(52.dp),
            shape = RoundedCornerShape(14.dp),
            colors = ButtonDefaults.buttonColors(containerColor = Color.Transparent),
            contentPadding = ButtonDefaults.ContentPadding
        ) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(
                        brush = Brush.horizontalGradient(listOf(Primary, Secondary)),
                        shape = RoundedCornerShape(14.dp)
                    ),
                contentAlignment = Alignment.Center
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.Center
                ) {
                    Icon(
                        imageVector = Icons.Default.Image,
                        contentDescription = null,
                        tint = Color.White,
                        modifier = Modifier.size(18.dp)
                    )
                    Spacer(modifier = Modifier.width(Spacing.small))
                    Text(
                        text = "Choose Photo",
                        style = MaterialTheme.typography.titleSmall,
                        fontWeight = FontWeight.SemiBold,
                        color = Color.White
                    )
                }
            }
        }

        Spacer(modifier = Modifier.height(Spacing.xLarge))

        // Tips Section
        TipsSection(isDark = isDark)

        Spacer(modifier = Modifier.height(Spacing.large))
    }
}

@Composable
private fun TipsSection(isDark: Boolean) {
    val shape = RoundedCornerShape(CornerRadius.large)
    val backgroundColor = if (isDark) CardBackgroundDark else CardBackgroundLight
    val borderBrush = glassBorderBrush(isDark)

    Column(
        modifier = Modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(Spacing.compact)
    ) {
        Text(
            text = "TIPS FOR BEST RESULTS",
            style = MaterialTheme.typography.labelSmall,
            color = Primary,
            fontWeight = FontWeight.Medium,
            letterSpacing = 1.sp
        )

        Column(
            modifier = Modifier
                .fillMaxWidth()
                .then(
                    if (!isDark) Modifier.shadow(12.dp, shape, spotColor = ShadowColor, ambientColor = ShadowColor)
                    else Modifier
                )
                .clip(shape)
                .background(backgroundColor)
                .border(1.dp, borderBrush, shape)
                .padding(Spacing.medium),
            verticalArrangement = Arrangement.spacedBy(Spacing.compact)
        ) {
            TipRow(text = "Include fund names and current values")
            TipRow(text = "Ensure text is clearly visible")
            TipRow(text = "Crop to show only relevant holdings")
        }
    }
}

@Composable
private fun TipRow(text: String) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(Spacing.compact)
    ) {
        Icon(
            imageVector = Icons.Default.CheckCircle,
            contentDescription = null,
            tint = Success,
            modifier = Modifier.size(14.dp)
        )
        Text(
            text = text,
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

// ---- Shared Utility ----

@Composable
private fun glassBorderBrush(isDark: Boolean): Brush {
    return if (isDark) {
        Brush.linearGradient(
            colors = listOf(
                GlassBorderStartDark,
                GlassBorderMidDark,
                GlassBorderEndDark
            )
        )
    } else {
        Brush.linearGradient(
            colors = listOf(
                GlassBorderStartLight,
                GlassBorderMidLight,
                GlassBorderEndLight
            )
        )
    }
}
