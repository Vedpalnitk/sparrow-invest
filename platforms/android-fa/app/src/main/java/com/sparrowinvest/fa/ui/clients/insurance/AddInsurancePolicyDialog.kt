package com.sparrowinvest.fa.ui.clients.insurance

import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.sparrowinvest.fa.data.model.CreateInsurancePolicyRequest
import com.sparrowinvest.fa.ui.theme.Primary
import com.sparrowinvest.fa.ui.theme.Spacing

private val POLICY_TYPES = listOf(
    "TERM_LIFE" to "Term Life",
    "WHOLE_LIFE" to "Whole Life",
    "ENDOWMENT" to "Endowment",
    "ULIP" to "ULIP",
    "HEALTH" to "Health",
    "CRITICAL_ILLNESS" to "Critical Illness",
    "PERSONAL_ACCIDENT" to "Personal Accident",
    "OTHER" to "Other"
)

private val FREQUENCIES = listOf(
    "MONTHLY" to "Monthly",
    "QUARTERLY" to "Quarterly",
    "HALF_YEARLY" to "Half Yearly",
    "ANNUAL" to "Annual",
    "SINGLE" to "Single"
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddInsurancePolicyDialog(
    onDismiss: () -> Unit,
    onSave: (CreateInsurancePolicyRequest) -> Unit
) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)

    var policyNumber by remember { mutableStateOf("") }
    var provider by remember { mutableStateOf("") }
    var selectedType by remember { mutableStateOf("TERM_LIFE") }
    var sumAssured by remember { mutableStateOf("") }
    var premiumAmount by remember { mutableStateOf("") }
    var premiumFrequency by remember { mutableStateOf("ANNUAL") }
    var startDate by remember { mutableStateOf("") }
    var maturityDate by remember { mutableStateOf("") }
    var nominees by remember { mutableStateOf("") }
    var notes by remember { mutableStateOf("") }

    val isValid = policyNumber.isNotBlank() && provider.isNotBlank() &&
        sumAssured.toDoubleOrNull() != null && sumAssured.toDouble() > 0 &&
        premiumAmount.toDoubleOrNull() != null && premiumAmount.toDouble() > 0 &&
        startDate.isNotBlank()

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = Spacing.medium, vertical = Spacing.compact),
            verticalArrangement = Arrangement.spacedBy(Spacing.compact)
        ) {
            Text(
                text = "Add Insurance Policy",
                style = MaterialTheme.typography.titleMedium,
                color = MaterialTheme.colorScheme.onSurface
            )

            OutlinedTextField(
                value = policyNumber,
                onValueChange = { policyNumber = it },
                label = { Text("Policy Number") },
                placeholder = { Text("e.g. LIC-87654321") },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true
            )

            OutlinedTextField(
                value = provider,
                onValueChange = { provider = it },
                label = { Text("Provider") },
                placeholder = { Text("e.g. LIC, HDFC Life") },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true
            )

            // Policy Type chips
            Text(
                text = "Policy Type",
                style = MaterialTheme.typography.labelMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Row(
                modifier = Modifier.horizontalScroll(rememberScrollState()),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                POLICY_TYPES.forEach { (value, label) ->
                    FilterChip(
                        selected = selectedType == value,
                        onClick = { selectedType = value },
                        label = { Text(label, style = MaterialTheme.typography.labelSmall) },
                        colors = FilterChipDefaults.filterChipColors(
                            selectedContainerColor = Primary.copy(alpha = 0.15f),
                            selectedLabelColor = Primary
                        )
                    )
                }
            }

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(Spacing.compact)
            ) {
                OutlinedTextField(
                    value = sumAssured,
                    onValueChange = { sumAssured = it },
                    label = { Text("Sum Assured (₹)") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                    modifier = Modifier.weight(1f),
                    singleLine = true
                )
                OutlinedTextField(
                    value = premiumAmount,
                    onValueChange = { premiumAmount = it },
                    label = { Text("Premium (₹)") },
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                    modifier = Modifier.weight(1f),
                    singleLine = true
                )
            }

            // Frequency chips
            Text(
                text = "Premium Frequency",
                style = MaterialTheme.typography.labelMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Row(
                modifier = Modifier.horizontalScroll(rememberScrollState()),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                FREQUENCIES.forEach { (value, label) ->
                    FilterChip(
                        selected = premiumFrequency == value,
                        onClick = { premiumFrequency = value },
                        label = { Text(label, style = MaterialTheme.typography.labelSmall) },
                        colors = FilterChipDefaults.filterChipColors(
                            selectedContainerColor = Primary.copy(alpha = 0.15f),
                            selectedLabelColor = Primary
                        )
                    )
                }
            }

            OutlinedTextField(
                value = startDate,
                onValueChange = { startDate = it },
                label = { Text("Start Date") },
                placeholder = { Text("YYYY-MM-DD") },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true
            )

            OutlinedTextField(
                value = maturityDate,
                onValueChange = { maturityDate = it },
                label = { Text("Maturity Date (optional)") },
                placeholder = { Text("YYYY-MM-DD") },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true
            )

            OutlinedTextField(
                value = nominees,
                onValueChange = { nominees = it },
                label = { Text("Nominees (optional)") },
                placeholder = { Text("e.g. Spouse - 100%") },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true
            )

            OutlinedTextField(
                value = notes,
                onValueChange = { notes = it },
                label = { Text("Notes (optional)") },
                modifier = Modifier.fillMaxWidth(),
                minLines = 2,
                maxLines = 3
            )

            // Action buttons
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = Spacing.small, bottom = Spacing.medium),
                horizontalArrangement = Arrangement.End
            ) {
                TextButton(onClick = onDismiss) {
                    Text("Cancel")
                }
                TextButton(
                    onClick = {
                        onSave(
                            CreateInsurancePolicyRequest(
                                policyNumber = policyNumber.trim(),
                                provider = provider.trim(),
                                type = selectedType,
                                sumAssured = sumAssured.toDouble(),
                                premiumAmount = premiumAmount.toDouble(),
                                premiumFrequency = premiumFrequency,
                                startDate = startDate.trim(),
                                maturityDate = maturityDate.ifBlank { null },
                                nominees = nominees.ifBlank { null },
                                notes = notes.ifBlank { null }
                            )
                        )
                    },
                    enabled = isValid
                ) {
                    Text("Save", color = if (isValid) Primary else MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
        }
    }
}
