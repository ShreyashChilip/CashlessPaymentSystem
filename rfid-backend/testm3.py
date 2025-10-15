import numpy as np
import matplotlib.pyplot as plt

# Data
x = np.array([1000, 2000, 3000, 4000, 5000])
y = np.array([120, 240, 330, 400, 490])

# Fit a linear regression line
m, c = np.polyfit(x, y, 1)
y_pred = m * x + c

# Plot
plt.scatter(x, y, color='blue', label='Actual data')
plt.plot(x, y_pred, color='red', label=f'Best fit line: y = {m:.2f}x + {c:.2f}')
plt.xlabel('Ad Spend (₹)')
plt.ylabel('App Downloads')
plt.legend()
plt.title('Regression Analysis: Ad Spend vs App Downloads')
plt.show()
